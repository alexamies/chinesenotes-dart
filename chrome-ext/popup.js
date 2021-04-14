const multiLookupSubmit = document.getElementById("multiLookupSubmit");
const multiLookupInput = document.getElementById("multiLookupInput");

multiLookupSubmit.onclick = function() {
  console.log(`multiLookupSubmit clicked: ${multiLookupInput.value}`);
}