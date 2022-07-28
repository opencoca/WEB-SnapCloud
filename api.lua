-- API module
-- ==========
--
-- See static/API for API description
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2019 by Bernat Romagosa and Michael Ball
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

local api_version = 'v2'

local app = package.loaded.app
local capture_errors = package.loaded.capture_errors
local respond_to = package.loaded.respond_to
local yield_error = package.loaded.yield_error

require 'validation'

require 'controllers.user'
require 'controllers.project'
require 'controllers.collection'

-- Wraps all API endpoints in standard behavior.
-- All API routes are nested under /api/v1,
-- which is currently an optional prefix.
local function api_route(path) return '/(api/' .. api_version .. '/)' .. path end

-- API Endpoints
-- =============
app:match(api_route('version'), respond_to({
    GET = capture_errors(function (self)
        return jsonResponse({
            name = 'Snap! Cloud',
            version = api_version
        })
    end)
}))

app:match(api_route('init'), respond_to({
    GET = capture_errors(function (self)
        return errorResponse(
            'It seems like you are trying to log in. ' ..
            'Try refreshing the page and try again. ' ..
            'This URL is internal to the Snap!Cloud.',
            400)
    end),
    POST = capture_errors(function (self)
        if not self.session.username or
            (self.session.username and
                self.cookies.persist_session == 'false') then
            self.session.username = ''
        end
    end)
}))

-- Session
-- =======
app:match(api_route('set_locale'), respond_to({
    POST = capture_errors(function (self)
        self.session.locale = self.params.locale
        return jsonResponse({ redirect = self.params.redirect })
    end)
}))

-- Current user
-- ============
app:get(api_route('users/c'), UserController.current) -- backwards compatibility
app:match(api_route('user'), respond_to({
    GET = UserController.current,
    DELETE = function (self)
        -- delete the current user
    end
}))

app:match(api_route('logout'), respond_to({
    GET = UserController.logout,
    POST = UserController.logout
}))

app:match(api_route('unbecome'), respond_to({
    POST = UserController.unbecome
}))

-- Other users
-- ===========
app:match(api_route('signup'), respond_to({
    POST = function (self)
        -- create a new user
    end,
}))

app:match(api_route('users/:username/newpassword'), respond_to({
    POST = function (self)
    end
}))

app:match(api_route('users/:username/password_reset'), respond_to({
    POST = UserController.reset_password
}))

app:match(api_route('users/:username/login'), respond_to({
    POST = function(self)
        self.params.password = self.params.body
        return UserController.login(self)
    end
}))

app:match(api_route('users/:username/resendverification'), respond_to({
    POST = function (self)
    end
}))

-- Projects
-- ========
app:match(api_route('projects'), respond_to({
    -- get my projects
    GET = function (self)
    end
}))

app:match(api_route('projects/:username/:projectname'), respond_to({
    GET = function (self)
        -- get a public project
    end
}))

app:match(api_route('projects/:projectname'), respond_to({
    POST = function (self)
        -- create a project, owned by the current user
    end,
    DELETE = function (self)
    end
}))

app:match(api_route('projects/:username/:projectname/metadata'), respond_to({
    -- Needed? I don't think so.
    -- Let's instead make simpler routes for publish, unpublish, etc.
    GET = function (self)
    end,
    POST = function (self)
    end
}))

app:match(api_route('projects/:username/:projectname/versions'), respond_to({
    GET = function (self)
    end
}))

app:match(api_route('projects/:username/:projectname/thumbnail'), respond_to({
    GET = function (self)
        -- Get the thumbnail for a project of mine
    end
}))

-- Collections
-- ===========
app:match(api_route('collections/:username'), respond_to({
    POST = CollectionController.new
}))

app:match(api_route('collection/:id'),
    respond_to({
        DELETE = CollectionController.delete
    })
)


app:match(api_route('collection/:id/name'),
    respond_to({
        POST = CollectionController.rename
    })
)

app:match(api_route('collection/:id/description'),
    respond_to({
        POST = CollectionController.set_description
    })
)

app:match(api_route('collection/:id/editor'),
    respond_to({
        POST = CollectionController.add_editor,
        DELETE = CollectionController.remove_editor
    })
)

app:match(api_route('collection/:id/enrollment'),
    respond_to({
        DELETE = CollectionController.unenroll
    })
)

app:match(api_route('collection/:id/ffa'),
    respond_to({
        POST = CollectionController.make_ffa,
        DELETE = CollectionController.unmake_ffa
    })
)

app:match(api_route('collection/:id/sharing'),
    respond_to({
        POST = CollectionController.share,
        DELETE = CollectionController.unshare
    })
)

app:match(api_route('collection/:id/publishing'),
    respond_to({
        POST = CollectionController.publish,
        DELETE = CollectionController.unpublish
    })
)

app:match(api_route('collection/:id/thumbnail'),
    respond_to({
        POST = CollectionController.set_thumbnail
    })
)

app:match(api_route('collection/:id/project/:project_id'),
    respond_to({
        POST = CollectionController.add_project,
        DELETE = CollectionController.remove_project
    })
)

