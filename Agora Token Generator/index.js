const express = require('express');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const dotenv = require('dotenv'); // For loading environment variables
const cors = require('cors'); // For handling CORS

// Load environment variables from a .env file
dotenv.config();

// Express app setup
const app = express();
const port = process.env.PORT || 3000;

// Middleware to enable CORS (Cross-Origin Resource Sharing)
app.use(cors());

// Agora credentials from environment variables
const appId = process.env.AGORA_APP_ID;
const appCertificate = process.env.AGORA_APP_CERTIFICATE;

// Error handling: Checking for missing credentials
if (!appId || !appCertificate) {
    console.error('Agora App ID and App Certificate must be provided as environment variables.');
    process.exit(1); // Exit the process with an error code
}

// Function to generate RTC token (same as before, but using env vars)
function generateRtcToken(channelName, uid, role) {
    let token;
    const expirationTimeInSeconds = 3600; // Token expires in 1 hour 
    const currentTime = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTime + expirationTimeInSeconds;

    if (role === 'publisher' || role === 'host') {
        token = RtcTokenBuilder.buildTokenWithUid(appId, appCertificate, channelName, uid, RtcRole.ROLE_PUBLISHER, privilegeExpiredTs);
    } else {
        token = RtcTokenBuilder.buildTokenWithUid(appId, appCertificate, channelName, uid, RtcRole.ROLE_SUBSCRIBER, privilegeExpiredTs);
    }
    return token;
}

// RTC token endpoint
app.get('/rtc/:channelName/:uid/:role', (req, res) => {
    const channelName = req.params.channelName;
    const uid = parseInt(req.params.uid); // Ensuring uid is an integer
    const role = req.params.role;

    // Validate role
    if (role !== 'publisher' && role !== 'subscriber' && role !== 'host' && role !== 'audience') {
        return res.status(400).json({ error: 'Invalid role.  Must be publisher, subscriber, host, or audience.' });
    }
     // Validate Channel Name
    if (!channelName) {
        return res.status(400).json({ error: 'Channel name is required' });
    }

    // Validate UID
    if (isNaN(uid)) {
        return res.status(400).json({ error: 'UID must be a number' });
    }

    try {
        const token = generateRtcToken(channelName, uid, role);
        res.json({ token: token });
    } catch (error) {
        console.error('Error generating token:', error);
        res.status(500).json({ error: 'Failed to generate token: ' + error.message });
    }
});

// RTM token endpoint
app.get('/rtm/:userId', (req, res) => {
    const userId = req.params.userId;
    const expirationTimeInSeconds = 3600;
    const currentTime = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTime + expirationTimeInSeconds;
    try {
        const token = RtmTokenBuilder.buildToken(appId, appCertificate, userId, privilegeExpiredTs);
        res.json({ token: token });
    } catch (error) {
        console.error('Error generating RTM token:', error);
        res.status(500).json({ error: 'Failed to generate RTM token: ' + error.message });
    }
});

// Start the server
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
