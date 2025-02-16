const { SMTPServer } = require("smtp-server");
const fs = require("fs");

// Load TLS certificate
const options = {
  key: fs.readFileSync("key.pem"),
  cert: fs.readFileSync("cert.pem"),
};

const server = new SMTPServer({
  authOptional: true, // No authentication required
  secure: false, // STARTTLS will be used, not direct SSL
  allowInsecureAuth: true, // Allow plain text authentication
  key: options.key,
  cert: options.cert,
  onConnect(session, callback) {
    console.log("New SMTP connection established:", session);
    callback(); // Proceed with the connection
  },
  onMailFrom(address, session, callback) {
    console.log("MAIL FROM:", address.address);
    callback();
  },
  onRcptTo(address, session, callback) {
    console.log("RCPT TO:", address.address);
    callback();
  },
  onData(stream, session, callback) {
    let emailData = "";

    stream.on("data", (chunk) => {
      emailData += chunk;
    });

    stream.on("end", () => {
      console.log("Received Email:\n", emailData);
      callback(null);
    });
  },
});

module.exports = { server }