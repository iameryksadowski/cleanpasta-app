// Serves Cleanpasta's updates from R2: /updates/appcast.xml and /updates/<version>/Cleanpasta-<version>.zip.
// Anything else is 404; the root redirects to the repository until the site exists.

interface StoredObject {
  size: number;
  httpEtag: string;
  uploaded: Date;
}

interface StoredObjectBody extends StoredObject {
  body: ReadableStream;
}

interface Bucket {
  get(key: string): Promise<StoredObjectBody | null>;
  head(key: string): Promise<StoredObject | null>;
}

interface Env {
  RELEASES: Bucket;
}

const REPOSITORY = "https://github.com/iameryksadowski/cleanpasta-app";
const UPDATE_FILE = /^\/updates\/(appcast\.xml|\d+\.\d+\.\d+\/Cleanpasta-\d+\.\d+\.\d+\.zip)$/;

function plain(status: number, text: string, extra: Record<string, string> = {}): Response {
  return new Response(text, { status, headers: { "content-type": "text/plain; charset=utf-8", ...extra } });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return plain(405, "Method not allowed", { allow: "GET, HEAD" });
    }
    const url = new URL(request.url);
    if (url.pathname === "/") {
      return Response.redirect(REPOSITORY, 302);
    }
    if (!UPDATE_FILE.test(url.pathname)) {
      return plain(404, "Not found");
    }
    const key = url.pathname.slice(1);
    const object = request.method === "HEAD" ? await env.RELEASES.head(key) : await env.RELEASES.get(key);
    if (!object) {
      return plain(404, "Not found");
    }
    const isAppcast = key.endsWith(".xml");
    const headers = new Headers({
      "content-type": isAppcast ? "application/xml; charset=utf-8" : "application/zip",
      "content-length": String(object.size),
      etag: object.httpEtag,
      "last-modified": object.uploaded.toUTCString(),
      // The appcast changes with every release; an archive never changes once published.
      "cache-control": isAppcast ? "public, max-age=300" : "public, max-age=31536000, immutable",
      "x-content-type-options": "nosniff",
    });
    const body = "body" in object ? (object as StoredObjectBody).body : null;
    return new Response(request.method === "HEAD" ? null : body, { headers });
  },
};
