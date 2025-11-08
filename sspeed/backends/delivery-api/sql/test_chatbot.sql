-- Script de prueba para verificar el chatbot

-- 1. Verificar que la tabla de respuestas existe y tiene datos
SELECT COUNT(*) as total_respuestas FROM ia_respuestas_automaticas WHERE activo = TRUE;

-- 2. Ver algunas respuestas de ejemplo
SELECT id_respuesta_ia, intent, keywords, respuesta, prioridad
FROM ia_respuestas_automaticas
WHERE activo = TRUE
LIMIT 5;

-- 3. Verificar que la función fn_chatbot_match_predef existe
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'fn_chatbot_match_predef';

-- 4. Probar la función directamente
SELECT * FROM fn_chatbot_match_predef('hola', 'cliente', 'general', 'es');

-- 5. Verificar que el usuario del bot existe
SELECT id_usuario, nombre, correo FROM usuarios WHERE correo = 'chatbot@system.local';
