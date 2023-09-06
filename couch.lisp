(in-package :cl-couch)


(defvar +fv-normal+ "normal")
(defvar +fv-long-poll+ "longpoll")
(defvar +fv-continuous+ "continuous")
(defvar +fv-event-source+ "eventsource")
(defvar +batch-non+ "")
(defvar +batch-ok+ "ok")

(defvar +update-true+ "true")
(defvar +update-false+ "false")
(defvar +update-lazy+ "lazy")

(defvar +style-main-only+ "main_only")
(defvar +style-all-docs+ "all_docs")

(defvar +reshard-stopped+ "stopped")
(defvar +reshard-running+ "running")

(defvar +reduce-sum+ "_sum")
(defvar +reduce-count+ "_count")
(defvar +reduce-stats+ "_stats")
(defvar +reduce-approx-count-distinct+ "_approx_count_distinct")

(defclass couchdb-client ()
  ((base-url :accessor couchdb-url :initarg :url :initform (error "The Host must be specified."))
   (cookie :accessor couchdb-cookie :initarg :cookie :initform (cl-cookie:make-cookie-jar))
   (headers :accessor couchdb-headers :initarg :headers :initform '(("accept" . "application/json")
                                                                    ("Content-Type" . "application/json")))))



(defun new-couchdb (host port &key headers (scheme "http"))
  (let ((db (make-instance 'couchdb-client :url (quri:make-uri :host host :port port :scheme scheme))))
    db))


(defmacro couchdb-request (client path &key
                                         (stream nil)
                                         (parameters nil)
                                         (content nil)
                                         (method :get)
                                         (force-binary nil)
                                         (keep-alive t)
                                         (content-type "application/json")
                                         (accept "application/json")
                                         (preserve-uri))
  `(let ((resp
             (dexador:request (quri:merge-uris ,path (couchdb-url ,client))
                              :method ,method :headers (couchdb-headers ,client) :content ,content :cookie-jar (couchdb-cookie ,client) :want-stream ,stream :keep-alive ,keep-alive :force-binary ,force-binary)))



       resp))
  


(defun safe-alist (alist)
  (remove-if #'(lambda (list)
                 (null (cdr list))) alist))

(defmacro optional-js (&rest key-value-pairs)
  `(jsown:new-js ,@(remove-if (lambda (pair) (eq (cadr pair) nil)) key-value-pairs)))


(defmethod remove-auth ((client couchdb-client))
  (setf (couchdb-headers client) '(("accept" . "application/json")
                                   ("Content-Type" . "application/json")))
  (setf (couchdb-cookie client) (cl-cookie:make-cookie-jar)))

(defmethod password-auth ((client couchdb-client) username password)
  (let ((resp (couchdb-request client (quri:make-uri :path "/_session") :method :post :content (jsown:to-json* (jsown:new-js ("username" username)
                                                                                                                 ("password" password))))))

    resp))
(defmethod jwt-auth ((client couchdb-client) token)
  (setf (couchdb-headers client) (push (cons "Authorization" (format nil "Bearer ~a" token)) (couchdb-headers client))))

;; TODO I should make a macro for updating the headers
(defmethod proxy-auth ((client couchdb-client) username token roles)
  (setf (couchdb-headers client) (push (cons "X-Auth-CouchDB-Roles" (format nil "~{~a^,~}" roles)) (couchdb-headers client)))
  (setf (couchdb-headers client) (push (cons "X-Auth-CouchDB-UserName" username) (couchdb-headers client)))
  (setf (couchdb-headers client) (push (cons "X-Auth-CouchDB-Token" token) (couchdb-headers client))))


(defmethod server-info ((client couchdb-client))
;;; https://docs.couchdb.org/en/latest/api/server/common.html#api-server-root
  (couchdb-request client (quri:make-uri :path "/") :method :get))


(defmethod active-tasks ((client couchdb-client))
  ;;; https://docs.couchdb.org/en/latest/api/server/common.html#active-tasks
  (couchdb-request client (quri:make-uri :path "/_active_tasks/")))


(defmethod all-databases ((client couchdb-client) &key (descending "false") (limit nil) (skip 0) (start-key "[]") (end-key "[]"))
  (let ((uri (quri:make-uri :path "/_all_dbs/" :query (quri:url-encode-params (safe-alist `(("descending" . ,descending) ("skip" . ,skip) ("limit" . ,limit) ("start-key" . "[]") ("end-key" . "[]")))))))
    (couchdb-request client uri :method :get)))

(defmethod info ((client couchdb-client) keys)
  (couchdb-request client (quri:make-uri :path "/_dbs_info") :method :post :content (jsown:to-json* (jsown:new-js
                                                                                                      ("keys" keys)))))
(defmethod info* ((client couchdb-client) content)
  (couchdb-request client (quri:make-uri :path "/_dbs_info") :method :post :content content))


(defmethod updates ((client couchdb-client) feed-type &key (timeout 60) (since "now") (heartbeat 60000))
  (let ((uri (quri:make-uri :path "/_db_updates/" :query (quri:url-encode-params (safe-alist `(("feed" . ,feed-type)
                                                                                               ("since" . ,since)
                                                                                               ("timeout" . ,timeout)
                                                                                               ("heartbeat" . ,heartbeat)))))))
    (couchdb-request client uri)))

(defmethod membership ((client couchdb-client))
  (couchdb-request client (quri:make-uri :path "/_membership")))
(defmethod replicate ((client couchdb-client) source target &key (cancel "false")

                                                              (continuous "false")
                                                              (create-target "false")
                                                              (create-target-params "{}")
                                                              (winning_revs_only "false")
                                                              (doc_ids nil)
                                                              (filter nil)
                                                              (selector nil)
                                                              (source_proxy nil)
                                                              (target_proxy nil))
  (couchdb-request client (quri:make-uri :path "/_replicate") :method :post :content (jsown:to-json* (optional-js
                                                                                                      ("cancel" cancel)
                                                                                                      ("continuous" continuous)
                                                                                                      ("create-target" create-target)
                                                                                                      ("create-target-params" create-target-params)
                                                                                                      ("winning_revs_only" winning_revs_only)
                                                                                                      ("doc_ids" doc_ids)
                                                                                                      ("filter" filter)
                                                                                                      ("selector" selector)
                                                                                                      ("source_proxy" source_proxy)
                                                                                                      ("target_proxy" target_proxy)))))
(defmethod replicate* ((client couchdb-client) content)
  (couchdb-request client (quri:make-uri :path "/_replicate") :method :post :content content))


(defmethod cluster-setup ((client couchdb-client) &key (ensure-databases nil))
  (let ((uri (quri:make-uri :path "/_cluster_setup" :query (quri:url-encode-params (safe-alist `(("ensure-databases" . ,ensure-databases)))))))
   (couchdb-request client uri)))

(defmethod scheduler-jobs ((client couchdb-client) &key (limit 0) (skip 0))
  (let ((uri (quri:make-uri :path "/_scheduler/jobs" :query (quri:url-encode-params `(("limit" . ,limit) ("skip" . ,skip))))))
    (couchdb-request client uri)))

(defmethod scheduler-docs ((client couchdb-client) &key (limit 0) (skip 0))
  (let ((uri (quri:make-uri :path "/_scheduler/docs" :query (quri:url-encode-params (safe-alist `(("limit" . ,limit) ("skip" . ,skip)))))))
    (couchdb-request client uri)))

(defmethod scheduler-doc ((client couchdb-client) &key (replicator-database nil) (doc-id nil) (limit 0) (skip 0))
  (let ((uri (quri:make-uri :path  (format nil  "/_scheduler/docs/~a/~a" replicator-database doc-id) :query (quri:url-encode-params (safe-alist `(("limit" . ,limit) ("skip" . ,skip)))))))
    (couchdb-request client uri)))

(defmethod node-info ((client couchdb-client) &key (node "_local"))
  (let ((uri (quri:make-uri :path (format nil "/_node/~a" node))))
    (couchdb-request client uri)))

(defmethod node-stats ((client couchdb-client) &key (node "_local"))
  (let ((uri (quri:make-uri :path (format nil "/_node/~a/_stats" node))))
    (couchdb-request client uri)))

(defmethod node-system ((client couchdb-client) &key (node "_local"))
  (let ((uri (quri:make-uri :path (format nil "/_node/~a/_system" node))))
    (couchdb-request client uri)))

(defmethod node-restart ((client couchdb-client) &key (node "_local"))
  (let ((uri (quri:make-uri :path (format nil "/_node/~a/_restart" node))))
    (couchdb-request client uri)))

(defmethod search-analyze ((client couchdb-client) analyzer text)
  (couchdb-request client (quri:make-uri :path "/_search_analyze") :method :post :content (jsown:to-json* `(("analyzer" ,analyzer) ("text" ,text)))))

(defmethod reshard ((client couchdb-client))
  (couchdb-request client (quri:make-uri :path "/_reshard")))


;;; Database API
(defmethod database-exists-p ((client couchdb-client) database)
  (handler-case
      (progn
        (couchdb-request client (format nil "/~a" database) :method :head)
        t)
    (dexador:http-request-not-found nil)))

(defmethod document-exists-p ((client couchdb-client) database document)
  (handler-case
      (progn
        (couchdb-request client (format nil "/~a/~a" database document) :method :head)
        t)
    (dexador:http-request-not-found nil)))

(defmethod get-database ((client couchdb-client) database)

  (couchdb-request client (format nil "/~a" database)))
(defmethod create-database ((client couchdb-client) name &key
                                                           (q 1)
                                                           (n 1)
                                                           (partitioned "false"))
  (couchdb-request client (quri:make-uri :path (format nil "/~a" name) :query (quri:url-encode-params (safe-alist `(("q" . ,q)
                                                                                                                    ("n" . ,n)
                                                                                                                    ("partitioned" . ,partitioned)))))
                   :method :put))

(defmethod delete-database ((client couchdb-client) name)
  (couchdb-request client (quri:make-uri :path (format nil "/~a" name)) :method :delete))


;; TODO Make sure this is correct
(defmethod design-documents ((client couchdb-client) database &key (conflicts "false")
                                                                (descending "false")
                                                                (startkey "")
                                                                (endkey "")
                                                                (startkey_docid "")
                                                                (endkey_docid "")
                                                                (include_docs "")
                                                                (inclusive_end "true")
                                                                (key "")
                                                                (keys nil)
                                                                (limit 0)
                                                                (skip 0)
                                                                (update_seq "false"))
  (if (null keys)
      (couchdb-request client (quri:make-uri :path (format nil "/~a/_design_docs/" database) :query (quri:url-encode-params (safe-alist `(("conflicts" . ,conflicts)
                                                                                                                                          ("descending" . ,descending)
                                                                                                                                          ("startkey" . ,startkey)
                                                                                                                                          ("endkey" . ,endkey)
                                                                                                                                          ("startkey_docid" . ,startkey_docid)
                                                                                                                                          ("endkey_docid" . ,endkey_docid)
                                                                                                                                          ("include_docs" . ,include_docs)
                                                                                                                                          ("inclusive_end" . ,inclusive_end)
                                                                                                                                          ("key" . ,key)
                                                                                                                                          ("keys" . ,keys)
                                                                                                                                          ("limit" . ,limit)
                                                                                                                                          ("skip" . ,skip)
                                                                                                                                          ("update_seq" . ,update_seq)
                                                                                                                                          ("conflicts" . ,conflicts)
                                                                                                                                          ("descending" . ,descending)
                                                                                                                                          ("startkey" . ,startkey)
                                                                                                                                          ("endkey" . ,endkey)
                                                                                                                                          ("startkey_docid" . ,startkey_docid)
                                                                                                                                          ("endkey_docid" . ,endkey_docid)
                                                                                                                                          ("include_docs" . ,include_docs)
                                                                                                                                          ("inclusive_end" . ,inclusive_end)
                                                                                                                                          ("key" . ,key)
                                                                                                                                          ("limit" . ,limit)
                                                                                                                                          ("skip" . ,skip)
                                                                                                                                          ("update_seq" . ,update_seq))))))
      (couchdb-request client (quri:make-uri :path (format nil "/~a/_design_docs/" database)) :method :post :content (jsown:to-json* (jsown:new-js
                                                                                                                                       ("keys" keys))))))
(defmethod database-documents ((client couchdb-client) database)
  (couchdb-request client (format nil "/~a/_all_docs" database)))

(defmethod bulk-get-documents ((client couchdb-client) database documents &key (revs "false"))
  (couchdb-request client (quri:make-uri :path (format nil "/~a/_bulk_get" database) :query (quri:url-encode-params `(("revs" . ,revs)))) :method :post :content documents))

(defmethod bulk-get-documents* ((client couchdb-client) database documents &key (revs "false"))
  (bulk-get-documents client database (jsown:to-json* (jsown:new-js
                                                        ("docs" (mapcar #'(lambda (id)
                                                                            (jsown:new-js ("id" id))) documents))))))



;; documents is the full request object
(defmethod bulk-create-documents ((client couchdb-client) database documents)
  (couchdb-request client (quri:make-uri :path (format nil "/~a/_bulk_docs" database)) :method :post :content documents))

(defmethod bulk-create-documents* ((client couchdb-client) database documents &key (new-edits "false"))
  (bulk-create-documents client database (jsown:to-json (jsown:new-js ("docs" documents) ("new_edits" new-edits)))))





(defmethod mango-find ((client couchdb-client) database query-obj &key (explain nil))
  (couchdb-request client (quri:make-uri :path (format nil "/~a/~a" database (if explain "_explain" "_find"))) :method :post :content query-obj))


(defmethod mango-find* ((client couchdb-client) database query-obj &key (explain nil))
  (jsown:parse (mango-find client database query-obj :explain explain)))

(defmethod create-mango-index ((client couchdb-client) database index-obj &key (design-document-name nil)
                                                                        (name nil)
                                                                        (type nil)
                                                                        (partitioned "false"))
  (couchdb-request client (quri:make-uri :path (format nil "/~a/_index" database) :query (quri:url-encode-params (safe-alist `(
                                                                                                                               ("design-document-name" . ,design-document-name)
                                                                                                                               ("name" . ,name)
                                                                                                                               ("type" . ,type)
                                                                                                                               ("partitioned" . ,partitioned)))))
                   :method :post :content index-obj))


(defmethod mango-get-indexes ((client couchdb-client) database)
  (couchdb-request client (format nil "/~a/_index" database)))

(defmethod mango-delete-index ((client couchdb-client) database design-document-name index-name)
  (couchdb-request client (format nil "/~a/_index/~a/json/~a" database design-document-name index-name) :method :delete))

(defmethod database-shards ((client couchdb-client) database)
  (couchdb-request client (format nil "/~a/_shards" database)))
;; TODO
(defmethod database-shards-document ((client couchdb-client) database doc-id)
  (couchdb-request client (format nil "/~a/_shards/~a" database doc-id)))

(defmethod database-sync-shards ((client couchdb-client) database)
  (couchdb-request client (format nil "/~a/_sync_shards" database) :method :post))

(defmethod database-explain ((client couchdb-client ) database query-obj)
  (couchdb-client client (format nil "~/~a/_explain" database :content query-obj) :method :post))

(defmethod database-explain* ((client couchdb-client ) database query-obj)
  (couchdb-client client (format nil "~/~a/_explain" database ) :content (jsown:to-json query-obj) :method :post))

;; TODO
;; Use the database-changes-filter to filter on document ids
;; (defmethod database-changes ((client couchdb-client) database &key (feed +fv-normal+) (filter "")))

;;; CRUD


(defmethod create-document ((client couchdb-client) database doc &key (batch +batch-non+))
  (couchdb-request client (quri:make-uri :path (format nil "/~a" database)  :query (quri:url-encode-params `(("batch" . ,batch))))
                   :method :post :content doc))


;; Convert doc to json and insert
(defmethod create-document* ((client couchdb-client) database doc &key (batch +batch-non+))
  (couchdb-request client (quri:make-uri :path (format nil "/~a" database)  :query (quri:url-encode-params `(("batch" . ,batch))))
                :method :post :content (jsown:to-json* doc)))

(defmethod get-document ((client couchdb-client) database id)
  (couchdb-request client (quri:make-uri :path (format nil "/~a/~a" database id))))


(defmethod get-document* ((client couchdb-client) database id)
  (jsown:parse (couchdb-request client (quri:make-uri :path (format nil "/~a/~a" database id)))))


;; TODO Update document
;; You can always just  upload doc with create and include the _rev
