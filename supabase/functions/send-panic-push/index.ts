import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function base64UrlEncode(input: ArrayBuffer | string): string {
  let bytes: Uint8Array;

  if (typeof input === "string") {
    bytes = new TextEncoder().encode(input);
  } else {
    bytes = new Uint8Array(input);
  }

  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);

  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }

  return bytes.buffer;
}

async function getFirebaseAccessToken(serviceAccount: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const claimSet = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaimSet = base64UrlEncode(JSON.stringify(claimSet));
  const unsignedJwt = `${encodedHeader}.${encodedClaimSet}`;

  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(serviceAccount.private_key),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(unsignedJwt),
  );

  const jwt = `${unsignedJwt}.${base64UrlEncode(signature)}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(`Firebase access token failed: ${JSON.stringify(data)}`);
  }

  return data.access_token;
}

function normalizePhone(phone: string): string {
  return phone.replace(/\s+/g, "").trim();
}
function errorToMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }

  try {
    return JSON.stringify(error);
  } catch (_) {
    return String(error);
  }
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
   const serviceRoleKey =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("PROJECT_SERVICE_ROLE_KEY");
    const firebaseBase64 = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_BASE64");

    if (!supabaseUrl || !serviceRoleKey || !firebaseBase64) {
      throw new Error("Missing required Edge Function secrets");
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json().catch(() => ({}));

const panicUserId = body.panicUserId?.toString() ?? "";
const locationLink = body.locationLink?.toString() ?? "";
const liveTrackingToken = body.liveTrackingToken?.toString() ?? "";

if (!panicUserId) {
  throw new Error("Missing panic user id");
}

    const { data: trustedContacts, error: contactsError } = await supabaseAdmin
      .from("trusted_contacts")
      .select("name, phone_number")
      .eq("user_id", panicUserId);

    if (contactsError) {
      throw contactsError;
    }

    if (!trustedContacts || trustedContacts.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "No trusted contacts found",
          sentCount: 0,
        }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const trustedPhones = trustedContacts
      .map((contact) => normalizePhone(contact.phone_number ?? ""))
      .filter((phone) => phone.length > 0);

    const { data: profiles, error: profilesError } = await supabaseAdmin
      .from("user_profiles")
      .select("user_id, phone_number");

    if (profilesError) {
      throw profilesError;
    }

    const matchedUserIds = (profiles ?? [])
      .filter((profile) => {
        const profilePhone = normalizePhone(profile.phone_number ?? "");
        return trustedPhones.includes(profilePhone);
      })
      .map((profile) => profile.user_id)
      .filter(Boolean);

    const uniqueMatchedUserIds = [...new Set(matchedUserIds)];

    if (uniqueMatchedUserIds.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "No trusted contacts matched app users",
          sentCount: 0,
        }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const { data: pushTokens, error: tokensError } = await supabaseAdmin
      .from("user_push_tokens")
      .select("fcm_token")
      .in("user_id", uniqueMatchedUserIds);

    if (tokensError) {
      throw tokensError;
    }

    const tokens = [...new Set(
      (pushTokens ?? [])
        .map((row) => row.fcm_token)
        .filter(Boolean),
    )];

    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "Matched users found, but no FCM tokens found",
          sentCount: 0,
        }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const serviceAccountJson = new TextDecoder().decode(
      Uint8Array.from(atob(firebaseBase64), (c) => c.charCodeAt(0)),
    );

    const serviceAccount = JSON.parse(serviceAccountJson);
    const accessToken = await getFirebaseAccessToken(serviceAccount);

    let sentCount = 0;
    const errors: string[] = [];

    for (const token of tokens) {
      const fcmResponse = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: {
                title: "Amaan Emergency Alert",
                body: "A trusted contact pressed the panic button.",
              },
              data: {
                type: "panic_alert",
                locationLink,
                liveTrackingToken,
              },
              android: {
                priority: "HIGH",
              },
            },
          }),
        },
      );

      const fcmData = await fcmResponse.json();

      if (fcmResponse.ok) {
        sentCount++;
      } else {
        errors.push(JSON.stringify(fcmData));
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Push notification process completed",
        matchedAppUsers: uniqueMatchedUserIds.length,
        tokenCount: tokens.length,
        sentCount,
        errors,
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: errorToMessage(error),
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }
});
