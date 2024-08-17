-- Response utils
-- ==============
--
-- Written by Startr LLC team with major contributions by Bernat Romagosa & Michael Ball
--
-- Copyright (C) 2023 Startr LLC
-- Copyright (C) 2019 Bernat Romagosa and Michael Ball
--
-- This file is part of Snap Cloud.
--
-- Snap Cloud is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.


-- Responses

jsonResponse = function (json)
    return {
        layout = false,
        status = 200,
        readyState = 4,
        json = json or {}
    }
end

xmlResponse = function (xml)
    return {
        layout = false,
        status = 200,
        readyState = 4,
        content_type = "text/xml",
        xml
    }
end

okResponse = function (message)
    return jsonResponse({ message = message })
end

rawResponse = function (contents)
    return {
        layout = false,
        status = 200,
        readyState = 4,
        contents
    }
end

local html_error = function (self, error, status)
    status = status or 500
    self.locale = package.loaded.locale
    self.locale.language = self.session.locale or 'en'
    self.title = status .. ' Error'
    self.contents = error

    return { layout = 'layout', render = 'error', status = status }
end

errorResponse = function (self, err, status)
    local is_html_page = (self.req.headers['accept'] or ''):match('text/html')
    if is_html_page then
        return html_error(self, err, status)
    else
        return {
            layout = false,
            status = status or 500,
            readyState = 4,
            json = { errors = { err } }
        }
    end
end

htmlPage = function (self, title, contents)
    self.title = title
    self.contents = contents
    return { render = 'message' }
end
