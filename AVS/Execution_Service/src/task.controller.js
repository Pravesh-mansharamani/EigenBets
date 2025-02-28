"use strict";
const { Router } = require("express")
const CustomError = require("./utils/validateError");
const CustomResponse = require("./utils/validateResponse");
const oracleService = require("./oracle.service");
const dalService = require("./dal.service");

const router = Router()

router.post("/execute", async (req, res) => {
    console.log("Executing task");

    try {
        var taskDefinitionId = Number(req.body.taskDefinitionId) || 0;
        console.log(`taskDefinitionId: ${taskDefinitionId}`);

        // Extract input string from request
        const inputString = `Condition: Does the tweet state that the CEO of XYZ resigned?\nX post: "XYZ's CEO recently announced plans for expansion into Europe."`;
        
        if (!inputString) {
            return res.status(400).send(new CustomError("Input string is required", {}));
        }
        
        // Call the AI performer node to determine the outcome
        const aiResult = await oracleService.callPerformerNode(inputString);
        
        // Prepare data to be published to IPFS
        const resultData = {
            inputString: inputString,
            result: aiResult.result,
            timestamp: new Date().toISOString()
        };
        
        // Publish the result to IPFS
        const cid = await dalService.publishJSONToIpfs(resultData);
        
        // Send the task
        const data = JSON.stringify({ 
            inputString: inputString,
            result: aiResult.result
        });
        
        await dalService.sendTask(cid, data, taskDefinitionId);
        
        return res.status(200).send(
            new CustomResponse(
                {
                    proofOfTask: cid, 
                    data: data, 
                    taskDefinitionId: taskDefinitionId,
                    result: aiResult.result
                }, 
                "Task executed successfully"
            )
        );
    } catch (error) {
        console.log(error)
        return res.status(500).send(new CustomError("Something went wrong", {}));
    }
});

// Endpoint to submit a prediction market for validation
router.post("/create-prediction", async (req, res) => {
    try {
        const { inputString, endTime, taskDefinitionId } = req.body;
        
        if (!inputString) {
            return res.status(400).send(new CustomError("Input string is required", {}));
        }
        
        // Generate unique ID for prediction
        const predictionId = `pred_${Date.now()}_${Math.random().toString(36).substring(2, 10)}`;
        
        // Store prediction market data
        const predictionData = {
            id: predictionId,
            inputString,
            endTime: endTime || new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // Default 24h
            status: "pending",
            createdAt: new Date().toISOString(),
            taskDefinitionId: Number(taskDefinitionId) || 0
        };
        
        // Save individual prediction to IPFS
        const predictionCid = await dalService.publishJSONToIpfs(predictionData);
        
        // Get scheduler service and add to registry
        const schedulerService = require('./services/scheduler.service');
        await schedulerService.addPrediction({
            ...predictionData,
            predictionCid
        });
        
        return res.status(200).send(
            new CustomResponse(
                { 
                    predictionId,
                    predictionCid,
                    ...predictionData
                }, 
                "Prediction market created successfully"
            )
        );
    } catch (error) {
        console.log(error);
        return res.status(500).send(new CustomError("Failed to create prediction market", {}));
    }
});

// Endpoint to get all prediction markets
router.get("/predictions", async (req, res) => {
    try {
        const schedulerService = require('./services/scheduler.service');
        const predictions = await schedulerService.getPredictions();
        
        return res.status(200).send(new CustomResponse({ predictions }));
    } catch (error) {
        console.log(error);
        return res.status(500).send(new CustomError("Failed to fetch prediction markets", {}));
    }
});

// Endpoint to get a single prediction market
router.get("/predictions/:id", async (req, res) => {
    try {
        const schedulerService = require('./services/scheduler.service');
        const predictions = await schedulerService.getPredictions();
        const prediction = predictions.find(p => p.id === req.params.id);
        
        if (!prediction) {
            return res.status(404).send(new CustomError("Prediction market not found", {}));
        }
        
        return res.status(200).send(new CustomResponse({ prediction }));
    } catch (error) {
        console.log(error);
        return res.status(500).send(new CustomError("Failed to fetch prediction market", {}));
    }
});

module.exports = router
