/**
 * Reference variable to the active spreadsheet
 */
var ss = SpreadsheetApp.getActiveSpreadsheet();

/**
 * Function to run at script installation
 */
function onInstall() {
  onOpen();
}

/**
 * Function to run at spreadsheet file opening
 */
function onOpen() {
   // Build spreadsheet custom menu entries
   var menuEntries = [
                       {name: "Add backlog item", functionName: "addBacklogItemUI"},
                       {name: "Move item forward", functionName: "moveItemForward"},
                       {name: "Move item backward", functionName: "moveItemBackward"},
                       {name: "Move item up", functionName: "moveItemUp"},
                       {name: "Move item down", functionName: "moveItemDown"},
                       {name: "Set impediment on item", functionName: "itemImpediment"},
                       {name: "Remove impediment from item", functionName: "itemRemoveImpediment"},
                       {name: "Delete item", functionName: "deleteItem"},
                       {name: "Clear Kanban", functionName: "clearKanban"}
                     ];
    ss.addMenu("Personal Kanban", menuEntries);
}

/**
 * Add a new backlog item
 */
function addBacklogItemUI() {
  var app = UiApp.createApplication().setTitle('Add backlog item').setWidth(410).setHeight(370);
  var main_panel = app.createVerticalPanel().setStyleAttribute('border', '1px solid #C0C0C0');
  var settings_panel = app.createVerticalPanel().setPixelSize(400, 290).setId('settings_panel')
  var grid = app.createGrid(2, 2).setCellSpacing(20);
  settings_panel.add(grid);
  var button_panel = app.createHorizontalPanel().setWidth(400);
  var button_align = app.createHorizontalPanel().setSpacing(10);
  var close = app.createButton('Close', app.createServerHandler('closeApp_')).setWidth(100);
  button_panel.add(button_align);
  button_panel.setCellHorizontalAlignment(button_align, UiApp.HorizontalAlignment.CENTER);
  settings_panel.add(button_panel);
  main_panel.add(settings_panel);
  app.add(main_panel);
  
  grid.setWidget(0, 0, app.createLabel('Title:'));
  grid.setWidget(1, 0, app.createLabel('Description:'));
     
  var itemTitle = app.createTextBox().setName('itemTitle').setWidth('200');
  var itemDescription = app.createTextArea().setName('itemDescription').setWidth('200').setHeight('200');
     
  grid.setWidget(0, 1, itemTitle);
  grid.setWidget(1, 1, itemDescription);     
     
  var record = app.createButton("Save", app.createServerHandler('addBacklogItemClick').addCallbackElement(grid)).setEnabled(true);
  button_align.add(record.setWidth(100));
  button_align.add(close);
  ss.show(app);
}

/**
 * Close the running application
 */
function closeApp_() {
    var app = UiApp.getActiveApplication();
    app.close();
    return app;
}

/**
 * Handle creation of a new backlog item
 */
function addBacklogItemClick(e) {
  var app = UiApp.getActiveApplication();
  var itemTitle = e.parameter.itemTitle;
  var itemDescription = e.parameter.itemDescription;
  // @TODO CHECK NO MORE EMPTY RANGES!!!
  var freeItem = Kanban.getFreeItem("BACKLOG");
  Kanban.createItem(freeItem, itemTitle, itemDescription);
  closeApp_();
  return app;
}


/**
 * Move an item forward
 */
function moveItemForward() {
  var selectedCell = ss.getActiveCell().getA1Notation();
  var currentLane = Kanban.getLaneByCell(selectedCell);
  var nextLane = Kanban.getNextLane(currentLane);
  var freeItem = Kanban.getFreeItem(nextLane);
  var item = Kanban.getItemByCell(selectedCell);
  if(Kanban.isLastLane(currentLane) !== true) {
    Kanban.moveItem(item, freeItem);
    Kanban.reorderLane(currentLane);
  } else {
    return false;
  }

}

/**
 * Move an item backward
 */
function moveItemBackward() {
  var selectedCell = ss.getActiveCell().getA1Notation();
  var currentLane = Kanban.getLaneByCell(selectedCell);
  var prevLane = Kanban.getPrevLane(currentLane);
  var freeItem = Kanban.getFreeItem(prevLane);
  var item = Kanban.getItemByCell(selectedCell);
  if(Kanban.isFirstLane(currentLane) !== true) {
    Kanban.moveItem(item, freeItem);
    Kanban.reorderLane(currentLane);
  } else {
    return false;
  }  
}

/**
 * Move an item up
 */
function moveItemUp() {
  var selectedCell = ss.getActiveCell().getA1Notation();
  Kanban.moveItemUp(selectedCell);
}

/**
 * Move an item down
 */
function moveItemDown() {
  var selectedCell = ss.getActiveCell().getA1Notation();
  Kanban.moveItemDown(selectedCell);
}

/**
 * Delete an item
 */
function deleteItem() {
  var selectedCell = ss.getActiveCell().getA1Notation();
  var currentLane = Kanban.getLaneByCell(selectedCell);
  Kanban.deleteItem(selectedCell);
  Kanban.reorderLane(currentLane);
}

/**
 * Set impediment on item
 */
function itemImpediment() {
  var selectedCell = ss.getActiveCell().getA1Notation();
  var item = Kanban.getItemByCell(selectedCell);
  Kanban.setImpediment(item);
}

/**
 * Remove impediment from item
 */
function itemRemoveImpediment() {
  var selectedCell = ss.getActiveCell().getA1Notation();
  var item = Kanban.getItemByCell(selectedCell);
  Kanban.removeImpediment(item);
}

/**
 * Clear the Kanban board
 */
function clearKanban() {
  Kanban.clear();
}
