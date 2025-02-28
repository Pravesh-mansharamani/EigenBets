"use strict";
const { Router } = require("express")
const CustomError = require("./utils/validateError");
const CustomResponse = require("./utils/validateResponse");
const validatorService = require("./validator.service");

const router = Router()

router.post("/validate", async (req, res) => {
    var proofOfTask = req.body.proofOfTask;
    console.log(`Validate task: proof of task: ${proofOfTask}`);
    try {
        const validationResult = await validatorService.validate(proofOfTask);
        // const validationResult = true;
        
        // Log the validation outcome
        console.log('Validation Result:', validationResult);
        console.log('Vote:', validationResult.isApproved ? 'Approve' : 'Not Approved');
        
        return res.status(200).send(new CustomResponse({
            approved: validationResult.isApproved,
            validatorResult: validationResult.validatorResult,
            performerResult: validationResult.performerResult,
            inputString: validationResult.inputString ? validationResult.inputString.substring(0, 100) + '...' : null // Truncate for response
        }));
    } catch (error) {
        console.log(error)
        return res.status(500).send(new CustomError("Something went wrong", {}));
    }
})

module.exports = router
