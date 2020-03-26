Import os

#+ Check if a file exists
#+
#+ This function checks if a file already exists
#+
#+ @param fileName the name of the file
#+ @param pathList a list of Paths using OS path separator
#+ @returnType STRING
#+ @return filename with full path or Null
#+
Public Function checkFile( fileName String, pathList String )
  Define
    strTok  base.Stringtokenizer,
    foundIt Boolean,
    path    String

  Let foundIt = False
  If pathList Is Null Then
    Let pathList="."||os.Path.pathSeparator()
  Else
    If pathList.getCharAt(pathList.getLength()) <> os.Path.pathSeparator() Then
      Let pathList = pathList.append(os.Path.pathSeparator())
    End If
    Let pathList=pathList.append("."||os.Path.pathSeparator())
  End If
  Let strTok = base.StringTokenizer.create(pathList,os.Path.pathSeparator())
  While strTok.hasMoreTokens()
    Let path = strTok.nextToken()
    If path.getCharAt(path.getLength())<>os.Path.separator() Then
      Let path = path.append(os.Path.separator())
    End If
    If os.Path.isFile(path||fileName) Then
      Let foundIt = True
      Exit While
    End If
  End While
  Return Iif(foundIt,path||fileName,Null)
End Function

#+ Create a file
#+
#+ This function creates a file
#+
#+ @param fileName the name of the file with its path
#+ @returnType INTEGER
#+ @return  0 if file created, error number if not
#+
Public Function createFile( fileName String )
  Define
    ch base.Channel,
    ok Integer

  Let ok = 0
  Try
    Let ch = base.Channel.create()
    Call ch.openFile( fileName, "w" )
    Call ch.close()
  Catch
    Let ok = Status
  End Try
  Return ok
End Function
