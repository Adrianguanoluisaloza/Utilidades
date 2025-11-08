// REEMPLAZAR en DeliveryApi.java línea ~1070, justo después de:
// var req = ctx.bodyAsClass(Payloads.ChatBotRequest.class);

// AGREGAR ESTAS 3 LÍNEAS:
if (req == null) throw new ApiException(400, "Request body obligatorio");
if (req.idRemitente == null || req.idRemitente <= 0) throw new ApiException(400, "idRemitente obligatorio");
if (req.mensaje == null || req.mensaje.trim().isEmpty()) throw new ApiException(400, "mensaje obligatorio");