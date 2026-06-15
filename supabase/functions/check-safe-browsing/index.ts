const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    const apiKey = Deno.env.get("GOOGLE_SAFE_BROWSING_API_KEY");

    if (!apiKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Google Safe Browsing API key is missing",
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

    const body = await req.json();
    const url = body.url;

    if (!url || typeof url !== "string") {
      return new Response(
        JSON.stringify({
          success: false,
          error: "URL is required",
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const googleResponse = await fetch(
      `https://safebrowsing.googleapis.com/v4/threatMatches:find?key=${apiKey}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          client: {
            clientId: "amaan-scam-detector",
            clientVersion: "1.0.0",
          },
          threatInfo: {
            threatTypes: [
              "MALWARE",
              "SOCIAL_ENGINEERING",
              "UNWANTED_SOFTWARE",
              "POTENTIALLY_HARMFUL_APPLICATION",
            ],
            platformTypes: ["ANY_PLATFORM"],
            threatEntryTypes: ["URL"],
            threatEntries: [
              {
                url: url,
              },
            ],
          },
        }),
      },
    );

    const result = await googleResponse.json();

    if (!googleResponse.ok) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Google Safe Browsing request failed",
          details: result,
        }),
        {
          status: googleResponse.status,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const matches = result.matches ?? [];
    const isUnsafe = matches.length > 0;

    return new Response(
      JSON.stringify({
        success: true,
        checkedUrl: url,
        isUnsafe: isUnsafe,
        riskLevel: isUnsafe ? "dangerous" : "safe",
        matches: matches,
        reasons: isUnsafe
          ? ["Google Safe Browsing found this URL in an unsafe threat list."]
          : ["Google Safe Browsing did not find this URL in known unsafe lists."],
      }),
      {
        status: 200,
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
        error: error instanceof Error ? error.message : String(error),
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
