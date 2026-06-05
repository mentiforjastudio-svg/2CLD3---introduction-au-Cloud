import json
import boto3
import hashlib
import secrets
import os
from datetime import datetime

# LocalStack injecte LOCALSTACK_HOSTNAME dans l'environnement Lambda
endpoint_url = "http://{}:4566".format(
    os.environ.get("LOCALSTACK_HOSTNAME", "localhost")
)
table_name = os.environ.get("TABLE_NAME", "users")

dynamodb = boto3.resource("dynamodb", endpoint_url=endpoint_url)
table = dynamodb.Table(table_name)

HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
}


def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return {"statusCode": 400, "headers": HEADERS,
                "body": json.dumps({"error": "Corps de requête invalide"})}

    email = body.get("email", "").strip().lower()
    password = body.get("password", "")

    if not email or not password:
        return {"statusCode": 400, "headers": HEADERS,
                "body": json.dumps({"error": "email et password sont requis"})}

    # Vérifier si l'utilisateur existe déjà
    response = table.get_item(Key={"email": email})
    if "Item" in response:
        return {"statusCode": 409, "headers": HEADERS,
                "body": json.dumps({"error": "Cet email est déjà utilisé"})}

    # Hacher le mot de passe
    password_hash = hashlib.sha256(password.encode()).hexdigest()

    # Générer un token de session
    token = secrets.token_hex(32)

    # Stocker l'utilisateur dans DynamoDB
    table.put_item(Item={
        "email": email,
        "password_hash": password_hash,
        "session_token": token,
        "created_at": datetime.utcnow().isoformat(),
    })

    return {
        "statusCode": 201,
        "headers": HEADERS,
        "body": json.dumps({
            "message": "Inscription réussie",
            "email": email,
            "token": token,
        }),
    }
