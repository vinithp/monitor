function smessage(method,message){
    chrome.runtime.sendMessage({"method":method,"message":message});  
}

//=========================================================

let button = document.getElementById("button");
let button2 = document.getElementById("button2");
let button3 = document.getElementById("button3");
let tool_button = document.getElementById("tool_button");
let tool_button2 = document.getElementById("tool_button2");
let tool_button3 = document.getElementById("tool_button3");
let tool_button4 = document.getElementById("tool_button4");

//==========================================================

smessage("call_background");
button.addEventListener("click",function(event){
    smessage(button.value) 
})
button2.addEventListener("click",function(event) {
    smessage(button2.value)
})
button3.addEventListener("click",function(event) {
    smessage(button3.value)  
})
tool_button.addEventListener("click",function(event) {
    smessage(tool_button.value)
})
tool_button2.addEventListener("click",function(event) {
    smessage(tool_button2.value)
})
tool_button3.addEventListener("click",function(event) {
    smessage(tool_button3.value)
})
tool_button4.addEventListener("click",function(event) {
    smessage(tool_button4.value)
})
