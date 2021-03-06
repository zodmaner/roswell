(in-package :ros.install)

(defvar *sigsegv-version* "2.10")

(defun sigsegv-setup (argv)
  (let* ((uri (format nil "http://ftpmirror.gnu.org/libsigsegv/libsigsegv-~A.tar.gz" *sigsegv-version*))
         (pos (position #\/ uri :from-end t))
         (path (merge-pathnames (format nil "archives/~A" (subseq uri (1+ pos))) (homedir)))
         (expand-dir (merge-pathnames (format nil "src/libsigsegv-~A/" *sigsegv-version*) (homedir))))
    (if (or (not (probe-file path))
            (get-opt "download.force"))
        (progn
          (format *error-output* "~&Downloading archive: ~A~%" uri)
          (force-output *error-output*)
          (download uri path)
          (format *error-output* " done.~%"))
        (format *error-output* "~&Skip downloading ~A.~%Specify 'download.force=t' to download it again.~%"
                uri))
    (expand path (ensure-directories-exist (merge-pathnames "src/" (homedir))))
    (format t "~&configure~%")
    (with-open-file (out (ensure-directories-exist
                          (merge-pathnames "impls/log/sigsegv/config.log" (homedir)))
                         :direction :output :if-exists :append :if-does-not-exist :create)
      (format out "~&--~&~A~%" (date))
      (let* ((cmd (format nil "./configure '--prefix=~A'" 
                          (ensure-directories-exist(merge-pathnames (format nil "lib/~A/~A/~A/~A/" (uname-m) (uname) "sigsegv" *sigsegv-version*) (homedir)))))
             (*standard-output* (make-broadcast-stream out #+sbcl(make-instance 'count-line-stream))))
        (uiop/os:chdir expand-dir)
        (format t "~&chdir ~A~%" expand-dir)
        (uiop/run-program:run-program cmd :output t :ignore-error-status t)))
    (format t "~&make~%")
    (with-open-file (out (ensure-directories-exist
                          (merge-pathnames "impls/log/sigsegv/make.log" (homedir)))
                         :direction :output :if-exists :append :if-does-not-exist :create)
      (format out "~&--~&~A~%" (date))
      (let* ((cmd (format nil "make"))
             (*standard-output* (make-broadcast-stream out #+sbcl(make-instance 'count-line-stream))))
        (uiop/run-program:run-program cmd :output t :ignore-error-status t)))
    (format t "~&install~%")
    (with-open-file (out (merge-pathnames "impls/log/sigsegv/install.log" (homedir))
                         :direction :output :if-exists :append :if-does-not-exist :create)
      (format out "~&--~&~A~%" (date))
      (let ((*standard-output* (make-broadcast-stream
                                out #+sbcl(make-instance 'count-line-stream))))
        (uiop/run-program:run-program "make install" :output t))
      (format *error-output* "done.~%")))
  (cons t argv))

(push `("sigsegv" . ,(list
                     'sigsegv-setup))
      *install-cmds*)

(defun sigsegv-help (argv)
  (format t "~%")
  (cons t argv))

(push `("sigsegv" . ,(list 'sigsegv-help)) *help-cmds*)
