(asdf:defsystem :cl-couch-tests
  :version      "0.1.0"
  :description  "cl-couch test-suite"
  :author       " <unseen@flake>"
  :serial       t
  :license      "GNU GPL, version 3"
  :components   ((:file "package")
                 (:file "server-info")
                 (:file "database"))
  :depends-on   (#:cl-couch #:fiveam))
