#!/usr/bin/env lua

local Request = require 'Spore.Request'

require 'Test.More'

plan(49)

local env = {
    HTTP_USER_AGENT = 'MyAgent',
    PATH_INFO       = '/restapi',
    REQUEST_METHOD  = 'PET',
    SERVER_NAME     = 'services.org',
    SERVER_PORT     = 9999,
    spore = {
        url_scheme = 'prot',
        params = {
            prm1 = 1,
            prm2 = "value2",
            prm3 = "Value Z",
            oauth_prm = "valO",
        },
        headers = {
            auth = "OAuth :oauth_prm",
        }
    },
}
local req = Request.new(env)
type_ok( req, 'table', "Spore.Request.new" )
is( req.env, env )
is( req.redirect, false )
type_ok( req.headers, 'table' )
is( req.headers['user-agent'], 'MyAgent' )
type_ok( req.finalize, 'function' )
is( req.url, nil )
is( req.method, nil )

env.PATH_INFO = '/restapi/usr:prm1/show/:prm2'
env.QUERY_STRING = nil
req:finalize(true)
is( req.method, 'PET', "method" )
is( req.url, 'prot://services.org:9999/restapi/usr1/show/value2?prm3=Value%20Z', "url" )
is( env.PATH_INFO, '/restapi/usr1/show/value2' )
is( env.QUERY_STRING, 'prm3=Value%20Z' )
is( req.oauth_signature_base_string, 'PET&prot%3A%2F%2Fservices.org%3A9999%2Frestapi%2Fusr1%2Fshow%2Fvalue2&oauth_prm%3DvalO%26prm3%3DValue%2520Z', "OAuth signature base string" )
is( req.headers.auth, 'OAuth valO' )
req.oauth_signature_base_string = nil
req.headers.auth = nil

env.PATH_INFO = '/restapi/:prm3/show'
env.QUERY_STRING = nil
env.REQUEST_METHOD = 'TEP'
req:finalize(true)
is( req.method, 'TEP', "method" )
is( req.url, 'prot://services.org:9999/restapi/Value%20Z/show?prm1=1&prm2=value2', "url" )
is( env.PATH_INFO, '/restapi/Value%20Z/show' )
is( env.QUERY_STRING, 'prm1=1&prm2=value2' )
is( req.oauth_signature_base_string, 'TEP&prot%3A%2F%2Fservices.org%3A9999%2Frestapi%2FValue%2520Z%2Fshow&oauth_prm%3DvalO%26prm1%3D1%26prm2%3Dvalue2', "OAuth signature base string" )
is( req.headers.auth, 'OAuth valO' )
req.oauth_signature_base_string = nil
req.headers.auth = nil

env.PATH_INFO = '/restapi/usr:prm1/show/:prm2'
env.QUERY_STRING = nil
env.spore.params.prm3 = nil
env.spore.params.oauth_prm = nil
req:finalize()
is( req.url, 'prot://services.org:9999/restapi/usr1/show/value2', "url" )
is( env.PATH_INFO, '/restapi/usr1/show/value2' )
is( env.QUERY_STRING, nil )
is( req.oauth_signature_base_string, nil )

env.PATH_INFO = '/restapi/usr:prm1/show/:prm2'
env.QUERY_STRING = nil
env.spore.params.prm2 = 'path2/value2'
req:finalize()
is( req.url, 'prot://services.org:9999/restapi/usr1/show/path2/value2', "url" )
is( env.PATH_INFO, '/restapi/usr1/show/path2/value2' )
is( env.QUERY_STRING, nil )
env.spore.params.prm2 = 'value2'

env.PATH_INFO = '/restapi/doit'
env.QUERY_STRING = 'action=action1'
req:finalize(true)
is( req.url, 'prot://services.org:9999/restapi/doit?action=action1&prm1=1&prm2=value2', "url" )
is( env.PATH_INFO, '/restapi/doit' )
is( env.QUERY_STRING, 'action=action1&prm1=1&prm2=value2' )
is( req.oauth_signature_base_string, 'TEP&prot%3A%2F%2Fservices.org%3A9999%2Frestapi%2Fdoit&action%3Daction1%26prm1%3D1%26prm2%3Dvalue2', "OAuth signature base string" )
req.oauth_signature_base_string = nil

env.PATH_INFO = '/restapi/path'
env.QUERY_STRING = nil
env.spore.params.prm3 = "Value Z"
env.spore.form_data = {
    form1 = 'f(:prm1)',
    form2 = 'g(:prm2)',
    form3 = 'h(:prm3)',
    form7 = 'r(:prm7)',
}
req:finalize()
is( req.url, 'prot://services.org:9999/restapi/path', "url" )
is( env.PATH_INFO, '/restapi/path' )
is( env.QUERY_STRING, nil )
is( env.spore.form_data.form1, "f(1)", "form-data" )
is( env.spore.form_data.form2, "g(value2)" )
is( env.spore.form_data.form3, "h(Value Z)" )
is( env.spore.form_data.form7, nil )

env.QUERY_STRING = nil
env.spore.form_data = nil
env.spore.headers = {
    head1 = 'f(:prm1)',
    Head2 = 'g(:prm2); :prm1',
    HeaD3 = 'h(:prm3)',
    HEAD7 = 'r(:prm7)',
}
req:finalize()
is( req.url, 'prot://services.org:9999/restapi/path', "url" )
is( env.PATH_INFO, '/restapi/path' )
is( env.QUERY_STRING, nil )
is( env.spore.form_data, nil )
is( req.headers.head1, "f(1)", "headers" )
is( req.headers.head2, "g(value2); 1" )
is( req.headers.head3, "h(Value Z)" )
is( req.headers.head7, nil )

env.QUERY_STRING = nil
env.spore.params.prm1 = 2
env.spore.params.prm2 = 'VALUE2'
req:finalize()
is( req.headers.head1, "f(2)", "headers" )
is( req.headers.head2, "g(VALUE2); 2" )
is( req.headers.head3, "h(Value Z)" )
