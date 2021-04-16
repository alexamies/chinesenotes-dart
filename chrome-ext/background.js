chrome.runtime.onInstalled.addListener(() => {
  console.log('running background script');
  chrome.contextMenus.create({
    "id": "cnotes",
    "title": "Chinese Notes ...",
    "contexts": ["selection"]
  });
});

chrome.contextMenus.onClicked.addListener((info) => {
  console.log(`CNotes context menu clicked ${info.selectionText}`);
});
