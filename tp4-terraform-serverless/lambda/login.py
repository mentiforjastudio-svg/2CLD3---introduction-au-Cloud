import json
import boto3
import hashlib
import os

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

    # Récupérer l'utilisateur
    response = table.get_item(Key={"email": email})
    if "Item" not in response:
        # Message volontairement vague pour ne pas révéler si l'email existe
        return {"statusCode": 401, "headers": HEADERS,
                "body": json.dumps({"error": "Email ou mot de passe incorrect"})}

    user = response["Item"]
    password_hash = hashlib.sha256(password.encode()).hexdigest()

    if user["password_hash"] != password_hash:
        return {"statusCode": 401, "headers": HEADERS,
                "body": json.dumps({"error": "Email ou mot de passe incorrect"})}

    return {
        "statusCode": 200,
        "headers": HEADERS,
        "body": json.dumps({
            "message": "Connexion réussie",
            "email": email,
            "token": user["session_token"],
        }),
    }
