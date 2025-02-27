import fetch from 'node-fetch';

async function makeHyperbolicRequest(inputString) {
    const url = 'https://api.hyperbolic.xyz/v1/chat/completions';
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkZXJtb3R0Y29sZUBnbWFpbC5jb20iLCJpYXQiOjE3NDA2NDcxOTd9.GS3_-4c78vnl0K5RmiBLE4HJuQmKxdEodYDv1o48vsk'
    };

    const messages = [
        {
            "role": "system",
            "content": "You are an AI agent working for a prediction market platform. Your job is to analyze X posts based on specific conditions provided by the user and determine if the post meets that condition. You will receive two pieces of information: The condition set by the user. The X post to analyze. Your task is to read the condition and the X post, and then decide whether the post satisfies the condition. You should respond with either 'yes' or 'no'. For example: Condition: Does the tweet mention that the stock price of XYZ is above $100? X post: 'XYZ stock is now at $105, up 5% from yesterday.' In this case, your response should be 'yes' because the stock price is above $100. Another example: Condition: Is the team's project among the top 6 announced in the tweet? X post: 'The top 6 projects are: Project A, Project B, Project C, Project D, Project E, Project F.' If the team's project is Project C, then your response should be 'yes'. You must be accurate and base your decision solely on context."
        },
        {
            "role": "user",
            "content": inputString
        }
    ];

    const body = {
        messages,
        model: "deepseek-ai/DeepSeek-V3",
        max_tokens: 512,
        temperature: 0.1,
        top_p: 0.9,
        stream: false
    };

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: headers,
            body: JSON.stringify(body)
        });

        const data = await response.json();
        console.log('API Response:', JSON.stringify(data, null, 2));
        return data;
    } catch (error) {
        console.error('Error making API request:', error);
        throw error;
    }
}

// Example usage
const testInput = `Condition: Is @ImTheBigP part of the eigen games tribute from @wlooblockchain?
Json data of tweets : [
  {
    "id": "1894811273759719901",
    "text": "Announcing our 43rd University Tribute:\\n\\n@fighting_ntropy from @camblockchains has entered the Eigen Games arena… https://t.co/lGMQGWDn40",
    "timestamp": 1740593186,
    "createdAt": "1970-01-21T03:29:53.186Z",
    "isReply": false,
    "isRetweet": false,
    "likes": 2,
    "retweetCount": 0,
    "replies": 0,
    "photos": [
      {
        "id": "1894811241660719104",
        "url": "https://pbs.twimg.com/media/Gku4yP-aoAAcNX6.jpg"
      }
    ],
    "videos": [],
    "urls": [],
    "permanentUrl": "https://twitter.com/buildoneigen/status/1894811273759719901",
    "quotedTweet": null,
    "hashtags": []
  },
  {
    "id": "1894587263553544522",
    "text": "bbq wif sozu 🥩🥩🥩🥩\n\nfriday february 28 \n\nhttps://t.co/QwCIf5dQZd https://t.co/rQNhg6JU0R",
    "timestamp": 1740539778,
    "createdAt": "1970-01-21T03:28:59.778Z",
    "isReply": false,
    "isRetweet": false,
    "likes": 47,
    "retweetCount": 7,
    "replies": 2,
    "photos": [
      {
        "id": "1894587178937630720",
        "url": "https://pbs.twimg.com/media/GkrtAFSWQAA5yBT.jpg"
      }
    ],
    "videos": [],
    "urls": [
      "https://lu.ma/ejuraa7v?tk=rVY3Pj"
    ],
    "permanentUrl": "https://twitter.com/buildoneigen/status/1894587263553544522",
    "quotedTweet": null,
    "quotedStatusId": "1894561937218048291",
    "hashtags": []
  },
  {
    "id": "1894581852096414187",
    "text": "Announcing our 42nd University Tribute:\n\n@mbastidas_0010 from @YaleBlockchain has entered the Eigen Games arena… https://t.co/F0wPyaCWIO",
    "timestamp": 1740538487,
    "createdAt": "1970-01-21T03:28:58.487Z",
    "isReply": false,
    "isRetweet": false,
    "likes": 45,
    "retweetCount": 4,
    "replies": 0,
    "photos": [
      {
        "id": "1894581448570499072",
        "url": "https://pbs.twimg.com/media/GkrnyiAW8AATT2c.jpg"
      }
    ],
    "videos": [],
    "urls": [],
    "permanentUrl": "https://twitter.com/buildoneigen/status/1894581852096414187",
    "quotedTweet": null,
    "hashtags": []
  },
  {
    "id": "1894508260369338772",
    "text": "Announcing our 41st University Tributes:\n\n@YoshiTheExplore and @ethancdr23 from @BadgerBlock have entered the Eigen Games arena… https://t.co/7KosDwLtWA",
    "timestamp": 1740520942,
    "createdAt": "1970-01-21T03:28:40.942Z",
    "isReply": false,
    "isRetweet": false,
    "likes": 3,
    "retweetCount": 0,
    "replies": 0,
    "photos": [
      {
        "id": "1894508026343628800",
        "url": "https://pbs.twimg.com/media/GkqlAy5WoAAXu6w.jpg"
      }
    ],
    "videos": [],
    "urls": [],
    "permanentUrl": "https://twitter.com/buildoneigen/status/1894508260369338772",
    "quotedTweet": null,
    "hashtags": []
  },
  {
    "id": "1894461922277294227",
    "text": "Day 2 of The Vault AI Hacker House with presentations from @0xOthentic @alt_layer @tangle_network @coinbase and @Mantle_Official. https://t.co/ZBQOdW15kC",
    "timestamp": 1740509894,
    "createdAt": "1970-01-21T03:28:29.894Z",
    "isReply": false,
    "isRetweet": false,
    "likes": 11,
    "retweetCount": 4,
    "replies": 0,
    "photos": [
      {
        "id": "1894460489658212352",
        "url": "https://pbs.twimg.com/media/Gkp5xy8XIAAP8U2.jpg"
      },
      {
        "id": "1894460489666633728",
        "url": "https://pbs.twimg.com/media/Gkp5xy-XoAAXCGC.jpg"
      },
      {
        "id": "1894460489658216448",
        "url": "https://pbs.twimg.com/media/Gkp5xy8XMAAZv7i.jpg"
      },
      {
        "id": "1894460489654026240",
        "url": "https://pbs.twimg.com/media/Gkp5xy7XQAA_cGv.jpg"
      }
    ],
    "videos": [],
    "urls": [],
    "permanentUrl": "https://twitter.com/buildoneigen/status/1894461922277294227",
    "quotedTweet": null,
    "hashtags": []
  },
  {
    "id": "1893883586702406107",
    "text": "Announcing our 40th University Tributes:\n\n@ChosenOne229 and @aaawonzo from @PennBlockchain have entered the Eigen Games arena… https://t.co/AdbYoqpI0P",
    "timestamp": 1740372008,
    "createdAt": "1970-01-21T03:26:12.008Z",
    "isReply": false,
    "isRetweet": false,
    "likes": 9,
    "retweetCount": 1,
    "replies": 2,
    "photos": [
      {
        "id": "1893883527332081665",
        "url": "https://pbs.twimg.com/media/GkhtCKyXsAED1jM.jpg"
      }
    ],
    "videos": [],
    "urls": [],
    "permanentUrl": "https://twitter.com/buildoneigen/status/1893883586702406107",
    "quotedTweet": null,
    "hashtags": []
  },
  {
    "id": "1893428155601342911",
    "text": "Eigen Games skiiii gear ⛷️ @collegedao_hub https://t.co/MseWqIUSFo",
    "timestamp": 1740263425,
    "createdAt": "1970-01-21T03:24:23.425Z",
    "isReply": false,
    "isRetweet": false,
    "likes": 25,
    "retweetCount": 0,
    "replies": 6,
    "photos": [
      {
        "id": "1893427912822403072",
        "url": "https://pbs.twimg.com/media/GkbOp6eWsAAyxXc.jpg"
      }
    ],
    "videos": [],
    "urls": [],
    "permanentUrl": "https://twitter.com/buildoneigen/status/1893428155601342911",
    "quotedTweet": null,
    "hashtags": []
  },
  {
    "id": "1893419186963259729",
    "text": "Announcing our 39th University Tributes:\n\n@CarlZielinski and @JerryJYZhang from @pton_blockchain have entered the Eigen Games arena… https://t.co/vVabyJ6qBt",
    "timestamp": 1740261286,
    "createdAt": "1970-01-21T03:24:21.286Z",
    "isReply": false,
    "isRetweet": false,
    "likes": 16,
    "retweetCount": 3,
    "replies": 5,
    "photos": [
      {
        "id": "1893418994352484352",
        "url": "https://pbs.twimg.com/media/GkbGiylbcAA67eX.jpg"
      }
    ],
    "videos": [],
    "urls": [],
    "permanentUrl": "https://twitter.com/buildoneigen/status/1893419186963259729",
    "quotedTweet": null,
    "hashtags": []
  },
  {
    "id": "1893368256192487800",
    "text": "Announcing our 38th University Tributes:\n\n@coledermo and @ImTheBigP from @wlooblockchain have entered the Eigen Games arena… https://t.co/trpIB8gVJ9",
    "timestamp": 1740249144,
    "createdAt": "1970-01-21T03:24:09.144Z",
    "isReply": false,
    "isRetweet": false,
    "likes": 11,
    "retweetCount": 3,
    "replies": 1,
    "photos": [
      {
        "id": "1893367966818779136",
        "url": "https://pbs.twimg.com/media/GkaYImNWQAAu859.jpg"
      }
    ],
    "videos": [],
    "urls": [],
    "permanentUrl": "https://twitter.com/buildoneigen/status/1893368256192487800",
    "quotedTweet": null,
    "hashtags": []
  }
]`;

makeHyperbolicRequest(testInput)
    .then(() => console.log('Request completed'))
    .catch(error => console.error('Request failed:', error));

// To run this script from command line with custom input:
if (process.argv[2]) {
    makeHyperbolicRequest(process.argv[2])
        .then(() => console.log('Custom request completed'))
        .catch(error => console.error('Custom request failed:', error));
} 