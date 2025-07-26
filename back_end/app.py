from flask import Flask, request, jsonify
from dotenv import load_dotenv
from flask_cors import CORS
from services.math_solver import  extract_text_from_doc, extract_text_from_pdf, solve_math_problem
from services.image_processing import extract_text_from_image
from services.image_processing import analyze_math_image
from models.solution import Solution
from models.history_item import HistoryItem
import os
import requests
import tempfile
from firebase.firebase_service import db
import firebase_admin
from firebase_admin import auth, firestore , credentials

app = Flask(__name__)
CORS(app)
load_dotenv() 



# Khởi tạo Firebase
if not firebase_admin._apps:
    service_account_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
    # Kiểm tra file tồn tại
    if not service_account_path or not Path(service_account_path).exists():
        raise ValueError("Firebase Service Account Key file not found or path not specified in .env")
    
    cred = credentials.Certificate(service_account_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# In-memory history (demo)
history_db = []

def verify_firebase_token(request):
    """Xác thực Firebase ID token từ header Authorization"""
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return None
    
    id_token = auth_header.split(' ')[1]
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except Exception as e:
        print(f"Token verification failed: {e}")
        return None

@app.route('/api/verify-token', methods=['POST'])
def verify_token():
    """API để verify Firebase ID token"""
    user = verify_firebase_token(request)
    if user:
        return jsonify({
            'success': True,
            'user': {
                'uid': user['uid'],
                'email': user['email']
            }
        })
    else:
        return jsonify({'error': 'Invalid token'}), 401

@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return jsonify({'error': 'Email và mật khẩu là bắt buộc'}), 400
    try:
        user = auth.create_user(email=email, password=password)
        return jsonify({'message': 'Đăng ký thành công', 'uid': user.uid})
    except firebase_admin._auth_utils.EmailAlreadyExistsError:
        return jsonify({'error': 'Email đã tồn tại'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return jsonify({'error': 'Email và mật khẩu là bắt buộc'}), 400
    # Firebase Admin SDK không hỗ trợ xác thực password trực tiếp
    # Thông thường, xác thực client sẽ dùng Firebase Auth REST API
    # Ở đây trả về lỗi hướng dẫn client dùng Firebase Auth SDK
    return jsonify({'error': 'Vui lòng sử dụng Firebase Auth SDK trên client để đăng nhập.'}), 400

@app.route('/api/solve', methods=['POST', 'OPTIONS'])
def solve():
    try:
        if request.method == 'OPTIONS':
            return _build_cors_response()

        # Debug: Log headers và form data
        print("Headers:", request.headers)
        print("Form data:", request.form)
        print("Files:", request.files)

        # Xác thực người dùng
        user = verify_firebase_token(request)
        user_id = user['uid'] if user else 'anonymous'

        print(f"User ID: {user_id}")

        # Chỉ nhận file qua URL (không dùng request.files)
        if 'fileUrl' not in request.form:
            return jsonify({'error': 'Missing fileUrl parameter'}), 400

        file_url = request.form['fileUrl']
        ext = request.form.get('fileType', 'pdf')  # Mặc định là PDF

        # Tải file từ URL
        try:
            response = requests.get(file_url, timeout=10)
            response.raise_for_status()  # Kiểm tra lỗi HTTP

            with tempfile.NamedTemporaryFile(delete=False, suffix=f'.{ext}') as tmp:
                tmp.write(response.content)
                file_path = tmp.name

            # Trích xuất nội dung
            if ext in ['jpg', 'jpeg', 'png']:
                problem_text = extract_text_from_image(file_path)
            elif ext == 'pdf':
                problem_text = extract_text_from_pdf(file_path)
            else:  # doc, docx
                problem_text = extract_text_from_doc(file_path)

            # Giải bài toán
            solution = solve_math_problem(problem_text)

            # Lưu vào Firestore
            doc_ref = db.collection('math_solutions').document()
            doc_ref.set({
                'user_id': user_id,
                'problem': problem_text,
                'solution': solution['solution'],
                'steps': solution['steps'],
                'file_type': ext,
                'created_at': firestore.SERVER_TIMESTAMP
            })

            return _build_cors_response(jsonify({
                'success': True,
                'solution': solution['solution'],
                'steps': solution['steps'],
                'problem_text': problem_text
            }))

        except requests.exceptions.RequestException as e:
            return jsonify({'error': f'Failed to download file: {str(e)}'}), 400
        finally:
            if 'file_path' in locals() and os.path.exists(file_path):
                os.remove(file_path)

    except Exception as e:
        print("Server error:", str(e))  # Log lỗi để debug
        return _build_cors_response(jsonify({
            'success': False,
            'error': 'Internal server error: ' + str(e)
        }), 500)
    
def _build_cors_response(response=None, status_code=200):
    if response is None:
        response = jsonify({'status': 'preflight'})
    response.headers.add("Access-Control-Allow-Origin", "*")
    response.headers.add("Access-Control-Allow-Headers", "*")
    response.headers.add("Access-Control-Allow-Methods", "*")
    return response, status_code  # Trả về cả response và status code

@app.route('/api/history', methods=['GET'])
def history():
    try:
        # Xác thực người dùng
        user = verify_firebase_token(request)
        if not user:
            return jsonify({'error': 'Unauthorized'}), 401

        # Lấy user_id từ token
        user_id = user['uid']

        # Truy vấn lịch sử từ Firestore với index đã tạo
        history_ref = db.collection('math_solutions')
        query = history_ref.where('user_id', '==', "anonymous") \
                         .order_by('created_at', direction=firestore.Query.DESCENDING) \
                         .limit(20)

        # Sử dụng get() thay vì stream() để bắt lỗi rõ ràng hơn
        docs = query.get()

        # Chuẩn bị dữ liệu trả về
        history_data = []
        for doc in docs:
            doc_data = doc.to_dict()
            history_data.append({
                'id': doc.id,
                'problem': doc_data.get('problem', ''),
                'solution': doc_data.get('solution', ''),
                'file_type': doc_data.get('file_type', ''),
                'created_at': doc_data.get('created_at').isoformat() if doc_data.get('created_at') else None,
                # Thêm các trường khác nếu cần
            })

        return jsonify({
            'success': True,
            'count': len(history_data),
            'history': history_data
        })

    except Exception as e:
        error_msg = f"Error fetching history: {str(e)}"
        print(error_msg)
        
        # Xử lý riêng lỗi thiếu index
        if "index" in str(e).lower():
            return jsonify({
                'success': False,
                'error': "Đang thiết lập cơ sở dữ liệu. Vui lòng thử lại sau ít phút.",
                'code': "missing_index"
            }), 503
        
        return jsonify({
            'success': False,
            'error': error_msg,
            'code': "server_error"
        }), 500
if __name__ == '__main__':
    app.run(debug=True) 