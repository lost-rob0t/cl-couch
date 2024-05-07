(in-package :couch.tests)

(in-suite couchdb-api)

(test create-delete-get
  (is (jsown:val (couch:create-database* *client* "cl-couch") "ok"))
  (is (jsown:val (couch:create-document* *client* "cl-couch" (jsown:new-js ("_id" "test1") ("msg" "hi"))) "ok"))
  (is (string= "hi" (jsown:val (couch:get-document* *client* "cl-couch" "test1") "msg")))
  (is (jsown:val (couch:delete-database* *client* "cl-couch") "ok")))
