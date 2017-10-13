//
//  ResultsViewController.swift
//  QRCaptureDemo
//
//  Created by Nicolás Miari on 2017/10/13.
//  Copyright © 2017 Nicolás Miari. All rights reserved.
//

import UIKit
import AVFoundation

class ResultsViewController: UITableViewController {

    var results = [AVMetadataObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)

        // Configure the cell...
        let object = results[indexPath.row]

        cell.textLabel?.text = ""
        cell.detailTextLabel?.text = object.type.rawValue
        cell.accessoryType = .none

        if object.type == .qr, let code = object as? AVMetadataMachineReadableCodeObject {
            cell.textLabel?.text = code.stringValue

            if codeObjectContainsLink(code) {
                cell.accessoryType = .disclosureIndicator
            }
        }
        return cell
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? WebViewController else {
            return
        }
        guard let indexPath = tableView.indexPathForSelectedRow else {
            return
        }
        guard let object = results[indexPath.row] as? AVMetadataMachineReadableCodeObject else {
            return
        }
        destination.url = firstLinkURL(in: object)
    }

    // MARK: - Internal Support

    private func codeObjectContainsLink(_ codeObject: AVMetadataMachineReadableCodeObject) -> Bool {
        guard let stringValue = codeObject.stringValue else {
            return false
        }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        let range = NSMakeRange(0, stringValue.characters.count)
        let matchCount = detector.numberOfMatches(in: stringValue, options: [], range: range)

        return matchCount > 0
    }

    private func firstLinkURL(in codeObject: AVMetadataMachineReadableCodeObject) -> URL? {
        guard let stringValue = codeObject.stringValue else {
            return nil
        }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSMakeRange(0, stringValue.characters.count)
        let matches = detector.matches(in: stringValue, options: [], range: range)

        return matches.flatMap{ $0.url }.first
    }
}
