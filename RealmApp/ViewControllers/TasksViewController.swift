//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import RealmSwift
import Foundation

class TasksViewController: UITableViewController {
    
    var taskList: TaskList!
    
    private var swipeRow: IndexPath!
    
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.name
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURRENT TASKS" : "COMPLETED TASKS"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        let task = indexPath.section == 0
            ? currentTasks[indexPath.row]
            : completedTasks[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = task.name
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let task = indexPath.section == 0
            ? currentTasks[indexPath.row]
            : completedTasks[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(indexPath.row, to: self.taskList)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, isDone in
            guard let tasks = indexPath.section == 0 ? self.currentTasks : self.completedTasks else { return }
            let task = tasks[indexPath.row]

            self.showAlert(with: task, title: "New Task", message: "What do you want to do?", type: .edit)
            isDone(true)
            self.swipeRow = indexPath
        }
        
        let doneButtonTitle = indexPath.section == 0 ? "Done" : "Undone"

        let doneAction = UIContextualAction(style: .normal, title: doneButtonTitle) {_, _, isDone in
            let anotherSectionIndex = indexPath.section == 0 ? 1 : 0;
            StorageManager.shared.done(to: task, is: !task.isComplete)
            tableView.reloadSections([anotherSectionIndex, indexPath.section], with: .automatic)
            isDone(true)
        }

        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction, doneAction])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc private func addButtonPressed() {
        showAlert(title: "New Task", message: "What do you want to do?")
    }

}

extension TasksViewController {
    
    private func showAlert(with task: Task? = nil, title: String, message: String, type: AlertType = .save) {
        
        let alert = AlertController.createAlert(withTitle: title, andMessage: message)
        
        alert.action(with: task) { newValue, note in
            if type == .save {
                self.saveTask(withName: newValue, andNote: note)
            } else if type == .edit {
                self.editTask(task, withName: newValue, andNote: note)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func saveTask(withName name: String, andNote note: String) {
        let task = Task(value: [name, note])
        StorageManager.shared.save(task, to: taskList)
        let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
        tableView.insertRows(at: [rowIndex], with: .automatic)
    }
    
    private func editTask(_ task: Task?, withName name: String, andNote note: String) {
        if let task = task {
            StorageManager.shared.edit(to: task, with: name, and: note)
            tableView.reloadRows(at: [swipeRow], with: .automatic)
        }
    }
}

extension TasksViewController {
    enum AlertType {
        case save
        case edit
    }
}
