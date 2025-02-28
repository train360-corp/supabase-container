const { test, expect } = require("@jest/globals");
const dotenv = require("dotenv");
const {createClient} = require("@supabase/supabase-js");
const {server} = require("./mock-smtp.js");

// loads .env files
dotenv.config({ path: "../.env" });


const getClient = () => createClient(process.env.SUPABASE_PUBLIC_URL, process.env.SUPABASE_ANON_KEY)


test("context loads", () => {})

test(".env loads", () => expect(process.env.SUPABASE_ANON_KEY).toBeTruthy())

test("create client", () => expect(getClient()).toBeTruthy())

test("empty user", async () => {
  server.listen(2500, () => {});
  const client = getClient();
  const result = await client.auth.getSession();
  expect(result.error).toBeFalsy();
  expect(result.data.session).toBeNull();
  await new Promise(resolve => server.close(resolve));
})

test("create user", async () => {
  const client = getClient();
  const result = await client.auth.signUp({
    email: "test23@test.com",
    password: "test123"
  });

  expect(result.error).toBeFalsy();
})