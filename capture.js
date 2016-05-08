var fs = require("fs"),
    system = require("system"),
    webpage = require("webpage"),
    webserver = require("webserver");

function parseQuery(qs) {
    return qs.split("&").reduce(
        function(q, part) {
            var pair = part.split("="),
                key = unescape(pair[0]),
                val = unescape(pair[1]);
            q[key] = val;
            return q;
        }, {});
}

function rpad(s, n, p) {
    s = "" + s;
    p = p || "0";

    n -= s.length;
    while (n--) {
        s = p + s;
    }

    return s;
}

function escapeURL(url) {
    return url.replace(/[\/:;"']+/g, "_");
}

var FORMATS = {
    png: {ext: "png", contentType: ""}
},
    IMG_URL = system.env["THUMBER_IMG_URL"] || "/thumb",
    IMG_DIR = system.env["THUMBER_IMG_DIR"] ||
        fs.workingDirectory + fs.separator + "thumb",
    PORT = system.env["PHANTOM_PORT"];

PORT = PORT ? parseInt(PORT) : 8080;


var server = webserver.create(),
    service = server.listen(PORT, function(request, response) {
        var url = request.url,
            urlParts = url.split("?"),
            query = parseQuery(urlParts[1]),
            fetchURL = query.url,
            format = query.format;

        if (!query.url) {
            response.statusCode = 401;
            response.closeGracefully();
            return;
        }

        if (!format)
            format = "png";

        var ext = FORMATS[format].ext,
            page = webpage.create();

        page.viewportSize = { width: 1280, height: 800 };

        page.open(fetchURL, function(status) {
            if (status === "success") {
                var now = new Date(),
                    sep = fs.separator,
                    dir = "" +
                        now.getUTCFullYear() +
                        rpad(now.getUTCMonth(), 2) +
                        rpad(now.getUTCDate(), 2),
                    dirpath = IMG_DIR + sep + dir,
                    timestr = [dir,
                               rpad(now.getUTCHours(), 2),
                               rpad(now.getUTCMinutes(), 2)].join(""),
                    filename = escapeURL(fetchURL) + "-" + timestr + "." + ext,
                    filepath = dirpath + sep + filename;

                fs.makeDirectory(dir);

                setTimeout(function() {
                    page.render(filepath);
                    page.close();

                    if (query.redirect) {
                        var redir_url = [IMG_URL, dir, filename].join(sep);
                        response.setHeader("Location", redir_url);
                        response.statusCode = 302;
                        response.write("");
                    } else {
                        response.statusCode = 200;
                        response.write(filepath);
                    }

                    response.close();
                }, 5000);
            } else {
                response.statusCode = 500;
                response.write("status:" + status);
                response.close();
            }
        });

    });
