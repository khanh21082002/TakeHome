import os
import requests
from PIL import Image
import pytesseract
import io
import PyPDF2
from docx import Document
import google.generativeai as genai
from typing import Dict, List
from urllib.parse import urlparse

# Cấu hình Gemini
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

def is_valid_url(url: str) -> bool:
    """Kiểm tra URL hợp lệ"""
    try:
        result = urlparse(url)
        return all([result.scheme, result.netloc])
    except ValueError:
        return False

def download_file(url: str) -> bytes:
    """Tải file từ URL"""
    if not is_valid_url(url):
        raise ValueError("URL không hợp lệ")
    
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    return response.content

def extract_text_from_image(image_path: str) -> str:
    """Trích xuất văn bản từ ảnh sử dụng OCR"""
    try:
        if is_valid_url(image_path):
            img = Image.open(io.BytesIO(download_file(image_path)))
        else:
            img = Image.open(image_path)
        
        # Cấu hình Tesseract cho tiếng Anh và Việt
        custom_config = r'--oem 3 --psm 6 -l eng+vie'
        text = pytesseract.image_to_string(img, config=custom_config)
        return " ".join(text.split())  # Chuẩn hóa khoảng trắng
    except Exception as e:
        raise ValueError(f"OCR Error: {str(e)}")

def extract_text_from_pdf(pdf_path: str) -> str:
    """Trích xuất text từ PDF"""
    try:
        if is_valid_url(pdf_path):
            pdf_content = download_file(pdf_path)
            with io.BytesIO(pdf_content) as f:
                reader = PyPDF2.PdfReader(f)
                text = "\n".join([page.extract_text() or "" for page in reader.pages])
        else:
            with open(pdf_path, 'rb') as f:
                reader = PyPDF2.PdfReader(f)
                text = "\n".join([page.extract_text() or "" for page in reader.pages])
        
        return text.strip() or "Không trích xuất được text từ PDF"
    except Exception as e:
        raise ValueError(f"PDF Processing Error: {str(e)}")

def extract_text_from_doc(doc_path: str) -> str:
    """Trích xuất text từ DOC/DOCX"""
    try:
        if is_valid_url(doc_path):
            doc_content = download_file(doc_path)
            with io.BytesIO(doc_content) as f:
                doc = Document(f)
                return "\n".join([para.text for para in doc.paragraphs if para.text])
        else:
            doc = Document(doc_path)
            return "\n".join([para.text for para in doc.paragraphs if para.text])
    except Exception as e:
        raise ValueError(f"DOC Processing Error: {str(e)}")

def solve_math_problem(problem_text: str) -> Dict[str, str | List[str]]:
    """Giải bài toán sử dụng Gemini API"""
    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        response = model.generate_content(
            f"""Bạn là trợ lý toán học chuyên nghiệp. Hãy giải bài toán sau theo từng bước chi tiết:
            
            {problem_text}
            
            Yêu cầu:
            1. Phân tích đề bài
            2. Giải từng bước rõ ràng
            3. Kết luận đáp án cuối cùng
            4. Sử dụng ngôn ngữ rõ ràng, dễ hiểu""",
            generation_config={
                "temperature": 0.7,
                "max_output_tokens": 2000,
                "top_p": 0.9
            }
        )
        
        content = response.text
        steps = _extract_steps_from_content(content)
        
        return {
            "solution": content,
            "steps": steps,
            "model": "gemini-1.5-flash"
        }
        
    except Exception as e:
        error_msg = str(e)
        if "quota" in error_msg.lower():
            return {
                "solution": "Hệ thống tạm thời quá tải. Vui lòng thử lại sau.",
                "steps": ["Lỗi: Đã vượt quá hạn mức API"],
                "error": "API quota exceeded"
            }
        raise ValueError(f"Gemini Error: {error_msg}")

def _extract_steps_from_content(content: str) -> List[str]:
    """Tách các bước giải từ nội dung AI trả về"""
    steps = []
    current_step = ""
    
    # Các pattern nhận diện bước giải
    step_patterns = ('bước', 'step', '-', '•', '*', '1.', '2.', '3.', '4.', '5.')
    
    for line in content.split('\n'):
        line_lower = line.strip().lower()
        if any(line_lower.startswith(pattern) for pattern in step_patterns):
            if current_step:
                steps.append(current_step.strip())
            current_step = line
        else:
            if line.strip():  # Bỏ qua dòng trống
                current_step += "\n" + line
    
    if current_step:
        steps.append(current_step.strip())
    
    return steps if steps else [content]
