(asdf:defsystem :cl-couch
  :description "CouchDB Client"
  :author "nsaspy"
  :license "MIT"
  :version "0.2.1"
  :serial t
  :depends-on (#:cl-cookie #:jsown #:dexador)
  :components ((:file "package")
               (:file "couch")))
