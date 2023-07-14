(asdf:defsystem :cl-couch
  :description "CouchDB Client"
  :author "nsaspy"
  :license "MIT"
  :version "0.1.0"
  :serial t
  :depends-on (#:cl-cookie #:jsown #:alexandria #:serapeum #:drakma #:dexador)
  :components ((:file "package")
               (:file "couch")))
