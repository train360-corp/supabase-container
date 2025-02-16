const { test, expect } = require("@jest/globals");
const dotenv = require("dotenv");
const {createClient} = require("@supabase/supabase-js");

// loads .env files
dotenv.config({ path: "../.env" });

const getClient = () => createClient(process.env.SUPABASE_PUBLIC_URL, process.env.SUPABASE_ANON_KEY)


test("context loads", () => {})

test(".env loads", () => expect(process.env.SUPABASE_ANON_KEY).toBeTruthy())

test("create client", () => expect(getClient()).toBeTruthy())

test("create user", async () => {
  const client = getClient();
  const result = await client.auth.signUp({
    email: "test@test.com",
    password: "test",
  });
  expect(result.error).toBeNull();
  expect(result.data.user).toBeTruthy();
})