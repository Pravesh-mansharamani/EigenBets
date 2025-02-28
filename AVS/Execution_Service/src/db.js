require('dotenv').config();
const mongoose = require('mongoose');

// Function to connect to MongoDB
async function connect() {
  try {
    const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/prediction-markets';
    
    await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    
    console.log('Connected to MongoDB successfully');
    return true;
  } catch (error) {
    console.error('Failed to connect to MongoDB:', error);
    return false;
  }
}

// Export the connection function
module.exports = {
  connect
};