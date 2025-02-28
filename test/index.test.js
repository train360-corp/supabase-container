const { test, expect, beforeAll, afterAll } = require("@jest/globals");
const dotenv = require("dotenv");
const {createClient} = require("@supabase/supabase-js");
const {server} = require("./mock-smtp.js");

// loads .env files
dotenv.config({ path: "../.env" });


const getClient = () => createClient(process.env.SUPABASE_PUBLIC_URL, process.env.SUPABASE_ANON_KEY)

// open SMTP server
beforeAll(async () => {
  await new Promise(resolve => server.listen(2500, resolve));
})

test("context loads", () => {})

test(".env loads", () => expect(process.env.SUPABASE_ANON_KEY).toBeTruthy())

test("create client", () => expect(getClient()).toBeTruthy())

test("empty user", async () => {
  const client = getClient();
  const result = await client.auth.getSession();
  expect(result.error).toBeFalsy();
  expect(result.data.session).toBeNull();
})

test("create user", async () => {
  const client = getClient();
  const result = await client.auth.signUp({
    email: "test23@test.com",
    password: "test123"
  });

  expect(result.error).toBeFalsy();
})

// close SMTP server
afterAll(async () => {
  await new Promise(resolve => server.close(resolve));
})