Schema salfatixmedia

Main
define img like users.usr_instagram_profilepicture

close window screen
open window w1 with form "img"
let img = "https://instagram.fcdg2-1.fna.fbcdn.net/v/t51.2885-19/s150x150/67455847_507628523390887_3568161230679965696_n.jpg?_nc_ht=instagram.fcdg2-1.fna.fbcdn.net&_nc_ohc=RXphG8VhKV8AX_eZQkH&oh=ae9ab0ced3a875363e39fd030ecad42e&oe=5EC4CFBA"
--let img = "https://instagram.fcdg2-1.fna.fbcdn.net/v/t51.2885-19/s150x150/61122344_2080199455608236_5107534125825261568_n.jpg?_nc_ht=instagram.fcdg2-1.fna.fbcdn.net&_nc_ohc=cS0rUfU286YAX86Z2PF&oh=6a4ca1bee8524202b84967a5a7ba72de&oe=5ED5C5E4"
Display By Name img
Menu "wait"
  Command "Exit"
    Exit Menu
End Menu

close window w1
exit program

{
define lstr_signature string

let lstr_signature = "aaa\nbbb\fzzz eee! qqq\rsss"
display lstr_signature
  While lstr_signature.getIndexOf(" ",1)>0
    Let lstr_signature = lstr_signature.subString(1,lstr_signature.getIndexOf(" ",1)-1),lstr_signature.subString(lstr_signature.getIndexOf(" ",1)+1,lstr_signature.getLength())
  End While
  While lstr_signature.getIndexOf("!",1)>0
    Let lstr_signature = lstr_signature.subString(1,lstr_signature.getIndexOf("!",1)-1),lstr_signature.subString(lstr_signature.getIndexOf("!",1)+1,lstr_signature.getLength())
  End While
  While lstr_signature.getIndexOf("\n",1)>0
    Let lstr_signature = lstr_signature.subString(1,lstr_signature.getIndexOf("\n",1)-1),lstr_signature.subString(lstr_signature.getIndexOf("\n",1)+1,lstr_signature.getLength())
  End While
  While lstr_signature.getIndexOf("\f",1)>0
    Let lstr_signature = lstr_signature.subString(1,lstr_signature.getIndexOf("\f",1)-1),lstr_signature.subString(lstr_signature.getIndexOf("\f",1)+1,lstr_signature.getLength())
  End While
  While lstr_signature.getIndexOf("\r",1)>0
    Let lstr_signature = lstr_signature.subString(1,lstr_signature.getIndexOf("\r",1)-1),lstr_signature.subString(lstr_signature.getIndexOf("\r",1)+1,lstr_signature.getLength())
  End While
display lstr_signature
exit program
}

  Try
    Connect To "salfatixmedia"
    Display "Ok"
  Catch
    Display sqlca.sqlcode," ",SQLERRMESSAGE
  End Try
End Main