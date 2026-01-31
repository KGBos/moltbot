import os
import io
import torch
import soundfile as sf
import torchaudio
from flask import Flask, request, send_file, jsonify
from chatterbox.tts_turbo import ChatterboxTurboTTS

app = Flask(__name__)

# Global model variable
model = None

def load_model():
    global model
    if model is not None:
        return

    print("Loading Chatterbox Turbo capability...")
    
    device = "cpu"
    if torch.cuda.is_available():
        device = "cuda"
        print("Using CUDA")
    elif torch.backends.mps.is_available():
        device = "mps"
        print("Using MPS (Apple Silicon)")
    else:
        print("Using CPU")

    try:
        # Load the Turbo model (optimized for agents)
        model = ChatterboxTurboTTS.from_pretrained(device=device)
        print("Chatterbox Turbo loaded successfully!")
    except Exception as e:
        print(f"Failed to load model: {e}")
        raise e

@app.route('/health', methods=['GET'])
def health():
    if model is None:
        return jsonify({"status": "loading"}), 503
    return jsonify({"status": "ready", "device": str(model.device)}), 200

@app.route('/tts', methods=['POST'])
def tts():
    if model is None:
        return jsonify({"error": "Model not loaded"}), 503

    data = request.json
    if not data or 'text' not in data:
        return jsonify({"error": "Missing 'text' in body"}), 400

    text = data['text']
    voice_prompt = data.get('voice_prompt') # Optional path to a reference wav
    
    try:
        # Generate audio
        # Turbo supports paralinguistic tags like [laugh] natively
        if voice_prompt and os.path.exists(voice_prompt):
            print(f"Generating with voice clone: {voice_prompt}")
            wav = model.generate(
                text, 
                audio_prompt_path=voice_prompt,
                temperature=0.8
            )
        else:
            print(f"Generating with default voice")
            wav = model.generate(text)
            
        # Convert to bytes
        buffer = io.BytesIO()
        
        # Determine format based upon output needs.
        # wav from chatterbox is (1, T). Squeeze for mono soundfile write.
        wav_np = wav.squeeze().cpu().numpy()
        
        sf.write(buffer, wav_np, model.sr, format='WAV')
        buffer.seek(0)
        
        return send_file(
            buffer,
            mimetype="audio/wav",
            as_attachment=False,
            download_name="output.wav"
        )

    except Exception as e:
        print(f"Generation error: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Load model on startup
    try:
        load_model()
    except Exception as e:
        print("FATAL: Could not load model.")
        exit(1)
        
    print("Starting server on port 5050...")
    app.run(host='0.0.0.0', port=5050)
