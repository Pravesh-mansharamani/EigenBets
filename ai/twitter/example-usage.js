// example-usage.js
import fetchTweets from './fetchTweets.js';

async function main() {
  try {
    // Fetch 15 latest tweets from @twitter
    const tweets = await fetchTweets('twitter', 15);
    
    console.log(`Fetched ${tweets.length} tweets`);
    
    // Example of processing tweets
    tweets.forEach((tweet, index) => {
      console.log(`\nTweet #${index + 1}:`);
      console.log(`Text: ${tweet.text.slice(0, 100)}${tweet.text.length > 100 ? '...' : ''}`);
      console.log(`Date: ${tweet.createdAt}`);
      console.log(`Likes: ${tweet.likes}, Retweets: ${tweet.retweetCount}`);
      
      if (tweet.isRetweet) {
        console.log('Type: Retweet');
      } else if (tweet.isReply) {
        console.log('Type: Reply');
      } else if (tweet.quotedTweet) {
        console.log('Type: Quote Tweet');
        console.log(`Quoted: ${tweet.quotedTweet.text.slice(0, 50)}...`);
      } else {
        console.log('Type: Original Tweet');
      }
    });
    
    // Example: Filter only original tweets (not replies, retweets, or quotes)
    const originalTweets = tweets.filter(tweet => 
      !tweet.isReply && !tweet.isRetweet && !tweet.quotedTweet
    );
    
    console.log(`\nFound ${originalTweets.length} original tweets`);
    
    // Example: Extract only text content
    const tweetTexts = tweets.map(tweet => tweet.text);
    console.log('\nJust the tweet texts:');
    tweetTexts.forEach((text, i) => console.log(`${i+1}: ${text.slice(0, 50)}...`));
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

main();