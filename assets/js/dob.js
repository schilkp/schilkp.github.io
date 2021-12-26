var dob = new Date("September 03, 1999");    
var year = new Date(Date.now() - dob.getTime()).getUTCFullYear();   
var age = Math.abs(year - 1970);  
document.write(age);  
