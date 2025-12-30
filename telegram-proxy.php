<?php
/**
 * Proxy HTTP para peticiones a la API de Telegram
 *
 * Este script recibe peticiones desde Laravel y las reenvía a api.telegram.org
 * para evitar el bloqueo de IP del servidor principal.
 */

header('Content-Type: application/json');

// Solo permitir método POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed. Use POST.']);
    exit;
}

// Leer el cuerpo de la petición
$input = file_get_contents('php://input');
$data = json_decode($input, true);

// Validar que se recibió JSON válido
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON']);
    exit;
}

// Validar parámetros requeridos
if (empty($data['bot_token']) || empty($data['method'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing bot_token or method']);
    exit;
}

$botToken = $data['bot_token'];
$method = $data['method'];
$params = $data['params'] ?? [];

// Construir URL de Telegram
$telegramUrl = "https://api.telegram.org/bot{$botToken}/{$method}";

// Inicializar cURL
$ch = curl_init();

// Configurar cURL
curl_setopt_array($ch, [
    CURLOPT_URL => $telegramUrl,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($params),
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 30,
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json'
    ],
    CURLOPT_SSL_VERIFYPEER => true,
    CURLOPT_SSL_VERIFYHOST => 2
]);

// Ejecutar petición
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);

curl_close($ch);

// Verificar errores de cURL
if ($response === false) {
    http_response_code(502);
    echo json_encode([
        'error' => 'Failed to connect to Telegram API',
        'details' => $curlError
    ]);
    exit;
}

// Devolver respuesta de Telegram con el mismo código HTTP
http_response_code($httpCode);
echo $response;
