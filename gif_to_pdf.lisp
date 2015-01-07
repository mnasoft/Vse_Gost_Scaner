;; Пример использования:
;; $ cd ~/Downloads
;; $ wget -m -np http://vsegost.com/
;; $ cd ~/MyDoc/git/mnasoft/Vse_Gost_Scaner/
;; $ clisp
;; > (load "compile_func.lsp")
;; > (load "gif_to_pdf.lsp")
;; > (load "open_file.lsp")
;; > (load "directory.lsp")
;; > (pth-Catalog->Data "/home/namatv/Downloads/vsegost.com/Catalog/**/*.shtml")     

(defvar *catalog-namber* 0)

(defun pth-name-format (str_path)
"Выводит на печать переменные, определенные в функции path-name-type."
  (let*
    ( (str_list (path-name-type str_path))
      (str_name (car str_list))
      (str_type (cadr str_list))
      (str_directory (caddr str_list)))
    (cond
      ( str_type 
        (format t "~a~a.~a~%" str_directory str_name str_type))
      ( (null str_type)
        (format t "~a~a~%" str_directory str_name )))))

(defun directory-list>directory-string (dlist)
"Выполняет сборку пути к каталогу, основываясь на результате вывода функции pathname-directory."
  (let
    ((str_rez ""))
    (mapcar
      (function
        (lambda (el)
          (cond
            ( (equal el :RELATIVE) (setq str_rez "./"))
            ( (equal el :ABSOLUTE) (setq str_rez "/"))
            ( (equal (quote SIMPLE-BASE-STRING) (car (type-of el)))
              (setq str_rez (string-concat str_rez el "/")))
            ( T (format t "~a~%" (type-of el))))))
      dlist)
    str_rez))

(defun pth-name-shtml (str_path)
"По имени shtml файла выполняет поиск каталога в, котором находятся gif файлы,
предназначенные для переименования"
  (let*
    ( (str_list (path-name-type str_path))
      (str_name (car str_list))
      (str_type (cadr str_list))
      (str_directory (trim-directory-from-tail (caddr str_list) "vsegost.com"))
      (str_rez ""))
    (cond
      ( (not (equal str_type "shtml")))
      ( (= 1 (length str_name))
        (setq str_rez (string-concat str_directory "./Data/0/" str_name "/")))
      ( (= 2 (length str_name))
        (setq str_rez (string-concat str_directory "./Data/0/" str_name "/")))
      ( (= 3 (length str_name))
        (setq str_rez (string-concat str_directory "./Data/" (substring str_name 0 1) "/" str_name "/")))
      ( (= 4 (length str_name))
        (setq str_rez (string-concat str_directory "./Data/" (substring str_name 0 2) "/" str_name "/")))
      ( (= 5 (length str_name))
        (setq str_rez (string-concat str_directory "./Data/" (substring str_name 0 3) "/" str_name "/"))))
    str_rez))

(defun rename-gif-file(str_path)
"Возвращает преобразованное имя файла, задаваемого в переменной str_path.
Преобразование заключается в том, что при длине имени в один символ имя предварялось символом 0.
Например: #P\"X.gif\" -> #P\"0X.gif\""
  (let 
    ( (str_rez "")
      (str_name (pathname-name str_path))
      (str_type (pathname-type str_path))
      (str_directory (directory-namestring str_path)))
    (if (null str_type) (setq str_type ""))
    (setq 
      str_rez
      (cond
        ( (<= (length str_name) 6 )
            (string-concat str_directory (make-string (- 6 (length str_name)) :initial-element  #\0) str_name "." str_type))
        ( (> (length str_name) 6)
          (string-concat str_directory str_name "." str_type))))
    (pathname str_rez)))

(defun path-name-type(str_path)
"Разбивает полное имя файла на: str_name - имя файла; str_type - расширение файла; str_directory - путь.
Возвращает путь к файлу.
Например: (path-name-type \"/usr/local/name.ext\") -> \"/usr/local/\"
str_name -> \"name\" ; str_type -> \"ext\" ; str_directory -> \"/usr/local/\". "
  (let 
    ( (str_name (pathname-name str_path))
      (str_type (pathname-type str_path))
      (str_directory (directory-namestring str_path)))
    (list str_name str_type str_directory)))

(defun trim-directory-from-tail(input_path find_directory)
"Возвращает путь, отсекая от пути input_path все каталоги начиная с конца
пока не встретится подкаталог с именем find_directory."
  (let
    ( (dir_str_list (reverse (pathname-directory input_path)))
      (if_vsegost_find nil))
    (mapcar
      (function
        (lambda (el)
          (cond
            ( if_vsegost_find T)
            ( (string= el find_directory) (setq if_vsegost_find T) T)
            ( (or (eq el :ABSOLUTE) (eq el :RELATIVE)))
            ( T (setq dir_str_list (cdr dir_str_list)) T))))
      dir_str_list)
    (directory-list>directory-string (reverse dir_str_list))))

(defun trim-directory-from-head(input_path find_directory)
"Возвращает путь, отсекая от пути input_path все каталоги начиная с начала
пока не встретится подкаталог с именем find_directory."
  (let
    ( (dir_str_list (reverse (pathname-directory input_path)))
      (if_vsegost_find nil)
      (dir_str_list_rez nil))
    (mapcar
      (function
        (lambda (el)
          (cond
            ( if_vsegost_find T)
            ( (string= el find_directory) (setq if_vsegost_find T) T)
            ( (or (eq el :ABSOLUTE) (eq el :RELATIVE)))
            ( T (setq dir_str_list_rez (cons el dir_str_list_rez)) T))))
      dir_str_list)
    (directory-list>directory-string dir_str_list_rez)))

(defun map-shtml-file(file_shtml)
"Для каждого shtml файла выполняет:
1 Поиск имен файлов с расширением gif в подходящем каталоге;
2 Создание отсортированного списка имен gif файлов и переименованных gif файлов;
3 Переименовывает gif фаайлы согласно схемы переименования;
4 При помощи внешней команды создает pdf файл;
5 Переименовывает gif фаайлы обратно схеме переименования.
"
  (let 
    ( (gif_file_from_to_list
        (sort ;; Сортируем список файлов с расширением gif.
          (mapcar
            (function
              (lambda (el) ;; Создаём список, содержащий пары имен файлов типа gif для переименования.
                  (list el (rename-gif-file el))))
            (directory
              (string-concat ;; Поиск файлов с расширением gif. 
                (pth-name-shtml file_shtml)
                "*.gif"))) 
          (function (lambda (el1 el2  )(string< (namestring (cadr el1))(namestring (cadr el2))))))))
    (mapcar ;; Выполняем прямое переименование.
      (function
        (lambda (el)
          (let 
            ( (car_el (car el)) (cadr_el (cadr el)))
            (if (string/= (namestring car_el) (namestring cadr_el))
              (rename-file car_el cadr_el)))))
      gif_file_from_to_list)
    (setq *catalog-namber* (1+ *catalog-namber*))
    (format t "~a       ~a~%" *catalog-namber* file_shtml) ;;Информационный вывод.
    (if gif_file_from_to_list
      (EXT:EXECUTE "/usr/bin/convert" 
        (string-concat (directory-namestring (cadr (car gif_file_from_to_list))) "*.gif") 
        (string-concat (directory-namestring (cadr (car gif_file_from_to_list))) "gost.pdf")))
    (mapcar ;; Выполняем обратное переименование.
      (function
        (lambda (el)
          (let ((car_el (car el)) (cadr_el (cadr el)))
            (if (string/= (namestring car_el) (namestring cadr_el))
              (rename-file cadr_el car_el)))))
      gif_file_from_to_list)))

(defun pth-Catalog->Data(str_catalog)
"
1 Выполняет поиск файлов с расширением *.shtml;
2 Для каждого имени файла выполняет поиск соответствующего ему каталога с фалами типа *.gif;
3 Выполняет сборку, найденных в пункте 2 файлов *.gif, в файл gost.pdf.
Пример:
(pth-Catalog->Data \"/home/namatv/Downloads/vsegost.com/Catalog/**/*.shtml\")
"
  (let 
    ((catalog_shtml_files (directory str_catalog)))
    (mapcar (function map-shtml-file) catalog_shtml_files)))

(compile-func-lst 
  '(pth-name-format 
  directory-list>directory-string 
  pth-name-shtml 
  rename-gif-file 
  path-name-type 
  trim-directory-from-tail 
  map-shtml-file 
  pth-Catalog->Data))