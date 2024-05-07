;; Server Info Api tests

(in-package :couch.tests)


(def-suite couchdb-api :description "Server  API")
(in-suite couchdb-api)

(defparameter *client* (couch:new-couchdb (uiop:getenv "COUCHDB_HOST") 5984))
(couch:password-auth *client* (uiop:getenv "COUCHDB_USER") (uiop:getenv "COUCHDB_PASSWORD"))

(test server-api-tests
  (is (string= "Welcome" (jsown:val (couch:server-info* *client*) "couchdb")))
  (is (not (couch:active-tasks* *client*)))
  (is (not (couch:all-databases* *client*)))
  (is (equal (couch:membership* *client*) '(:OBJ ("all_nodes" "couchdb@127.0.0.1") ("cluster_nodes" "couchdb@127.0.0.1"))))
  (is (equal (couch:scheduler-jobs* *client*) '(:OBJ ("total_rows" . 0) ("offset" . 0) ("jobs"))))
  (is (equal (couch:node-info* *client*) '(:OBJ ("name" . "couchdb@127.0.0.1"))))
  (is (> (length (couch:node-stats* *client*)) 0))
  (is (> (length (couch:node-system* *client*)) 0)))
