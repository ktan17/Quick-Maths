"use strict";

const express = require('express');
const multer = require('multer');
const { createCanvas, Image } = require('canvas');
const tf = require('@tensorflow/tfjs');
require("@tensorflow/tfjs-node");

const app = express();
const upload = multer();
let model;

app.get('/', (req, res) => {
    res.send("Hello, world!");
});

app.post('/', upload.array('digits', 12), (req, res, next) => {
    handleFiles(req.files, res);
    res.send("Hello, world!");
});

app.listen(3000, () => {
    loadModel();
    console.log("Listening on port 3000!");
});

function handleFiles(files, res) {
    Promise.all(files.map(file => {
        return new Promise((resolve, reject) => {
            let buffer = file.buffer;
            let image = new Image;

            image.onload = () => {
                const canvas = createCanvas(28, 28);
                const ctx = canvas.getContext('2d');

                ctx.drawImage(image, 0, 0);
                let imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);

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
    })).then(values => {
        for (const value of values) {
            let xs = tf.tensor2d(value, [1, 784]);
            const output = model.predict(xs.reshape([-1, 28, 28, 1]));
            const prediction = output.argMax(1).dataSync();
            console.log(prediction);
        }
    });
}

async function loadModel() {
    model = await tf.loadModel('file://./model/model.json');
    console.log("model loaded!");
}