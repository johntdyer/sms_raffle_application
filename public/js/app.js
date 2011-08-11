var user_name = null;
var email = null;
var phone_number = null;

jQuery(document).ready(function() {
  $("#results").hide();
  $("input#pick_winner").click(function(){
    $.ajax({
      url: '/get_winner',
      type: 'POST',
      dataType: 'json',
      complete: function(xhr, textStatus) {
      $("#results").show();
        console.log(xhr.responseText);
        winner = $.parseJSON(xhr.responseText);
        if(winner!=null){
          user_name = winner.user_name
          phone_number = winner.phone_number
          email = winner.email
          $("td#name").html(user_name);
          $("td#phone").html(phone_number);
          $("td#email").html(email);
        }else{
          $("td#name").html("-");
          $("td#phone").html("-");
          $("td#email").html("-");
        }
      },
      error: function(xhr, textStatus, errorThrown) {
        console.log("oh shit");
        console.log(xhr);
      }
    });
  });
  
  $("input#send_notification").click(function(){
    if(phone_number==null){
      console.log("No one to msg");
      $.gritter.add({
        title: "No one left",
        text: "There isnt anyone left",
        image: 'images/fail.png'
      });
    }else{
      $.ajax({
        url: '/send_notification',
        type: 'POST',
        dataType: 'json',
        data: "{'phone_number':"+phone_number+",'email':"+email+",'name':"+user_name+"}",
        complete: function(xhr, textStatus) {
          console.log(xhr.responseText);
          
         
        },
        error: function(xhr, textStatus, errorThrown) {
          console.log("oh shit");
          console.log(xhr);
        }
      });
    }
  });
  
  
  
});