
import base64
import os
import json
from subprocess import call
from flask import Flask, request

app = Flask(__name__)

@app.route('/', methods=['POST'])
def index():
    data = request.get_json()
    if not data:
        msg = 'no Pub/Sub message received'
        print(f'error: {msg}')
        return f'Bad Request: {msg}', 400

    if not isinstance(data, dict) or 'message' not in data:
        msg = 'invalid Pub/Sub message format'
        print(f'error: {msg}')
        return f'Bad Request: {msg}', 400
        
    pubsub_message = base64.b64decode(data['message']['data']).decode('utf-8').strip()
    payload = json.loads(pubsub_message)
    
    vm_name = payload['protoPayload']['resourceName'].split('/')[-1]
    vm_project = payload['resource']['labels']['project_id']
    vm_zone = payload['resource']['labels']['zone']

    os.environ['VM_NAME'] = vm_name
    os.environ['VM_ZONE'] = vm_zone
    os.environ['VM_PROJECT'] = vm_project
    
    rc = call("/scripts/myscript.sh")

    return ("OK", 200)

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
