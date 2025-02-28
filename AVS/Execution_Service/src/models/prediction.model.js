const mongoose = require('mongoose');

const PredictionSchema = new mongoose.Schema({
  inputString: {
    type: String,
    required: true,
  },
  ipfsCid: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'executed', 'validated', 'failed'],
    default: 'pending'
  },
  result: {
    type: String,
    enum: ['yes', 'no', 'undetermined', null],
    default: null
  },
  endTime: {
    type: Date,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  executedAt: {
    type: Date,
    default: null
  },
  taskDefinitionId: {
    type: Number,
    default: 0
  },
  tweetIds: {
    type: [String],
    default: []
  }
});

// Create index for finding pending predictions that need execution
PredictionSchema.index({ status: 1, endTime: 1 });

module.exports = mongoose.model('Prediction', PredictionSchema);