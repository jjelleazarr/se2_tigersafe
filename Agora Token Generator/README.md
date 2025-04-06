# Agora Token Generator Setup

This server generates Agora tokens for use in the TigerSafe App Emergency Call feature.

## Prerequisites

* Node.js 
* npm 
* An Agora account and project. (Janjan already have this set up)

## Setup

1.  **Set your terminal to the folder:**
    ```bash
    cd se2_tigersafe/Agora Token Generator  
    cd "Agora Token Generator" # use this if above is not working
    ```

2.  **Create the `.env` file:**
    * Create a file named `.env` in this directory.
    * Copy the following content into `.env`, and replace the values with your own:

        ```
        AGORA_APP_ID=YOUR_AGORA_APP_ID  # replace with the Agora App ID later
        AGORA_APP_CERTIFICATE=YOUR_AGORA_APP_CERTIFICATE # replace with the Agora App Certificate later
        TOKEN_SERVER_PORT=3000
        ```
    * **Get your Agora credentials:**
        * Contact Janjan to get the Agora App ID and App Certificate.

3.  **Install dependencies:**
    ```bash
    npm install  # or yarn install
    ```

4.  **Run the server:**
    ```bash
    node index.js  # or npm start, if you have that in package.json
    ```

## Configuration

* `AGORA_APP_ID`:  Your Agora App ID.
* `AGORA_APP_CERTIFICATE`: Your Agora App Certificate.
* `TOKEN_SERVER_PORT`:  The port the token server will listen on (default: 3000).  This should match the port in your Flutter/web app's `tokenServerUrl`.

## Important Security Note

* **Never** commit your `.env` file (which contains your App Certificate) to Git or any public repository.  It should only exist on your local machine and on your secure server.