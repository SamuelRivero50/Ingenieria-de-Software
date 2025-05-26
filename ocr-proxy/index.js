const express = require("express");
const multer = require("multer");
const cors = require("cors");
const axios = require("axios");
const FormData = require("form-data");

const app = express();
const upload = multer();

app.use(cors());
app.use(express.json());

app.post("/ocr", upload.single("image"), async (req, res) => {
    try {
        const apiKey = "K83755704588957"; // Reemplaza con tu API Key real si tienes otra

        const formData = new FormData();
        formData.append("file", req.file.buffer, "image.png");
        formData.append("language", "spa");
        formData.append("isOverlayRequired", "false");
        formData.append("OCREngine", "2");

        const response = await axios.post("https://api.ocr.space/parse/image", formData, {
            headers: {
                ...formData.getHeaders(),
                apikey: apiKey,
            },
        });

        res.status(200).json(response.data);
    } catch (error) {
        console.error("❌ OCR Error:", error.message);
        res.status(500).json({ error: "Error al procesar imagen" });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🟢 OCR Proxy funcionando en puerto ${PORT}`);
});
