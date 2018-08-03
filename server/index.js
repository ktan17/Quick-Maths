"use strict";

const express = require('express');
const multer = require('multer');
const { createCanvas, Image } = require('canvas');
const tf = require('@tensorflow/tfjs');
require("@tensorflow/tfjs-node");

const app = express();
const upload = multer();
const server = app.listen(process.env.port || 8080);
const io = require('socket.io')(server);

// MARK: - Helper Functions

async function loadModel() {
    const model = await tf.loadModel('file://./model/model.json');
    console.log("model loaded!");
    return model;
}
const modelPromise = loadModel();

async function handleFiles(files, res) {
    // Files is an array of images sent from the mobile client; extract the alpha
    // channels of each into an array
    const imageDrawRequests = files.map(file => {
        return new Promise((resolve, reject) => {
            const buffer = file.buffer;
            const image = new Image;

            image.onload = () => {
                const canvas = createCanvas(28, 28);
                const ctx = canvas.getContext('2d');

                ctx.drawImage(image, 0, 0);
                const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);

                // Image is 28 x 28 = 784, then each pixel is 4 values (RGBA)
                const alphaArray = [];
                for (let i = 0; i < 784; i++) {
                    alphaArray.push(imageData.data[(i * 4) + 3] / 255);
                }
                resolve(alphaArray);
            };
            image.onerror = err => {
                reject(err);
            };
            image.src = buffer;
        });  
    });
    const imageAlphaBuffers = await Promise.all(imageDrawRequests);
    const model = await modelPromise;

    // Feed each buffer of alpha channels to the ML model 
    const digits = [];
    for (const alphaBuffer of imageAlphaBuffers) {
        let xs = tf.tensor2d(alphaBuffer, [1, 784]);
        const output = model.predict(xs.reshape([-1, 28, 28, 1]));
        const prediction = output.argMax(1).dataSync()[0];
        digits.push(prediction);
    }

    // Emit the number to all clients
    io.emit('digit', Number(digits.join("")));
}

// MARK: - Express server and socket logic

app.get('/', (req, res) => {
    res.send("Hello, world!");
});

app.post('/', upload.array('digits', 12), (req, res, next) => {
    handleFiles(req.files, res);
    res.send("Hello, world!");
});

io.on('connection', (socket) => {
    console.log("got a connection!");
})