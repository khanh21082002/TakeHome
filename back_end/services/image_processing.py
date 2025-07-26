import io
import os
import requests
from typing import Dict, Tuple, Union
from PIL import Image
import google.generativeai as genai

# Configure APIs
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
HF_API_KEY = os.getenv('HUGGINGFACE_API_KEY')  # Add your Hugging Face API key to environment variables

def extract_text_from_image(image_path: str) -> Tuple[str, str]:
    """
    Extract text from image using Google Gemini Vision with Hugging Face API as fallback
    Returns: (text, error) - error is None if successful
    """
    try:
        # 1. Prepare image as PIL Image
        with Image.open(image_path) as img:
            # Convert to RGB if needed (Gemini requires RGB)
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            # First try Gemini
            try:
                model = genai.GenerativeModel('gemini-1.5-flash')
                response = model.generate_content(
                    contents=[
                        "Extract all text exactly as shown, including math formulas and numbers. Return raw text only.",
                        img  # Pass PIL Image directly
                    ],
                    generation_config={
                        "max_output_tokens": 2000,
                        "temperature": 0.0
                    }
                )
                text = response.text.strip()
                return (text, None)
                
            except Exception as gemini_error:
                print(f"Gemini failed, using Hugging Face API fallback: {str(gemini_error)}")
                
                # Fallback to Hugging Face API
                API_URL = "https://api-inference.huggingface.co/models/microsoft/trocr-large-printed"
                headers = {"Authorization": f"Bearer {HF_API_KEY}"}
                
                # Convert image to bytes for Hugging Face API
                img_byte_arr = io.BytesIO()
                img.save(img_byte_arr, format='PNG')
                img_bytes = img_byte_arr.getvalue()
                
                response = requests.post(API_URL, headers=headers, data=img_bytes)
                
                if response.status_code != 200:
                    return (None, f"Hugging Face API error: {response.text}")
                
                result = response.json()
                
                if isinstance(result, list) and len(result) > 0:
                    text = result[0].get('generated_text', '')
                    return (text.strip(), None)
                else:
                    return (None, "Hugging Face API returned no results")

    except Exception as e:
        return (None, f"Extraction failed: {str(e)}")

def analyze_math_image(image_path: str) -> Dict[str, Union[str, Dict]]:
    """
    Analyze math problem image and return detailed solution
    Returns: {
        "text": extracted text,
        "analysis": analysis from Gemini,
        "steps": solution steps (if any),
        "error": error message (if any)
    }
    """
    result = {
        "text": "",
        "analysis": "",
        "steps": [],
        "error": None
    }

    try:
        # 1. Extract input text
        text, error = extract_text_from_image(image_path)
        if error:
            raise Exception(error)
        result["text"] = text

        # 2. Analyze with Gemini
        model = genai.GenerativeModel('gemini-pro')
        prompt = f"""
        Bạn là giáo viên toán. Hãy phân tích bài toán sau:
        
        {text}
        
        Yêu cầu:
        1. Giải thích đề bài
        2. Trình bày lời giải từng bước
        3. Ghi chú kiến thức liên quan
        4. Định dạng đầu ra bằng Markdown
        """

        response = model.generate_content(
            prompt,
            generation_config={
                "max_output_tokens": 3000,
                "temperature": 0.3
            }
        )

        # 3. Process results
        full_response = response.text
        result["analysis"] = full_response
        
        # Extract solution steps if available
        if "**Steps:**" in full_response:
            result["steps"] = [
                step.strip() 
                for step in full_response.split("**Steps:**")[1].split("\n") 
                if step.strip()
            ]

        return result

    except Exception as e:
        result["error"] = f"Analysis failed: {str(e)}"
        return result