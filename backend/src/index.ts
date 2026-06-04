export interface Env {
  TELLUS_API_KEY: string;
  TELLUS_API_BASE: string;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Demo-Dry-Run",
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const base = env.TELLUS_API_BASE || "https://www.tellusxdp.com/api/traveler/v1";

    if (!env.TELLUS_API_KEY) {
      return json({ error: "TELLUS_API_KEY not configured" }, 500);
    }

    const headers = {
      Authorization: `Bearer ${env.TELLUS_API_KEY}`,
      Accept: "application/json",
      "Content-Type": "application/json",
    };

    try {
      if (url.pathname === "/api/datasets" && request.method === "GET") {
        const target = `${base}/datasets/${url.search}`;
        const resp = await fetch(target, { headers });
        return proxyResponse(resp);
      }

      const sceneMatch = url.pathname.match(
        /^\/api\/datasets\/([^/]+)\/data\/([^/]+)\/(.*)$/
      );
      if (sceneMatch && request.method === "GET") {
        const [, datasetId, dataId, rest] = sceneMatch;
        const target = `${base}/datasets/${datasetId}/data/${dataId}/${rest}${url.search}`;
        const resp = await fetch(target, { headers });
        return proxyResponse(resp);
      }

      if (url.pathname === "/api/search" && request.method === "POST") {
        const body = await request.text();
        const resp = await fetch(`${base}/data-search/`, {
          method: "POST",
          headers,
          body,
        });
        return proxyResponse(resp);
      }


      if (url.pathname === "/api/tellusar/jobs" && request.method === "POST") {
        const body = await request.text();
        const tellusarBase = base.replace("/traveler/v1", "/tellusar/v1");
        const resp = await fetch(`${tellusarBase}/jobs/`, {
          method: "POST",
          headers,
          body,
        });
        return proxyResponse(resp);
      }

      const tellusarJobMatch = url.pathname.match(/^\/api\/tellusar\/jobs\/([^/]+)\/?$/);
      if (tellusarJobMatch && request.method === "GET") {
        const tellusarBase = base.replace("/traveler/v1", "/tellusar/v1");
        const resp = await fetch(`${tellusarBase}/jobs/${tellusarJobMatch[1]}/`, { headers });
        return proxyResponse(resp);
      }


      if (url.pathname === "/api/purchased-data-search" && request.method === "POST") {
        const body = await request.text();
        const resp = await fetch(`${base}/purchased-data-search/`, {
          method: "POST",
          headers,
          body,
        });
        return proxyResponse(resp);
      }

      if (url.pathname === "/api/cart-items" && request.method === "POST") {
        const dryRun = request.headers.get("X-Demo-Dry-Run") === "true";
        if (dryRun) {
          const body = await request.json().catch(() => ({}));
          return json({
            ok: true,
            dryRun: true,
            message: "Demo cart recorded — no billing API called",
            items: (body as { dataset_ids?: string[] }).dataset_ids ?? [],
          });
        }
        const body = await request.text();
        const resp = await fetch(`${base}/cart-items/`, {
          method: "POST",
          headers,
          body,
        });
        return proxyResponse(resp);
      }

      if (url.pathname === "/api/dataset-orders" && request.method === "POST") {
        const dryRun = request.headers.get("X-Demo-Dry-Run") === "true";
        if (dryRun) {
          const body = await request.json().catch(() => ({}));
          return json({
            ok: true,
            dryRun: true,
            message: "Demo order recorded — no billing API called",
            order: body,
          });
        }
        const body = await request.text();
        const resp = await fetch(`${base}/dataset-orders/`, {
          method: "POST",
          headers,
          body,
        });
        return proxyResponse(resp);
      }

      if (url.pathname === "/api/search-conditions" && request.method === "GET") {
        const resp = await fetch(`${base}/search-conditions/${url.search}`, { headers });
        return proxyResponse(resp);
      }
      if (url.pathname === "/health") {
        return json({ status: "ok" });
      }

      return json({ error: "Not found" }, 404);
    } catch (err) {
      return json({ error: String(err) }, 502);
    }
  },
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function proxyResponse(resp: Response): Promise<Response> {
  const body = await resp.text();
  return new Response(body, {
    status: resp.status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
