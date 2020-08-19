//
//  BedNetCVC.swift
//  ComBest
//
//  Created by huanjia on 2019/8/30.
//  Copyright © 2019年 huanjia. All rights reserved.
//

import Foundation
import Reachability

class BedNetCVC: UIViewController {
    @IBOutlet weak var ssidTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var pwdEyeBtn: UIButton!
    
    // Reachability必须一直存在，所以需要设置为全局变量
    let reachability = Reachability.forInternetConnection()
    var mac: String?  //音箱mac地址
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "设置网络"
        NotificationCenter.default.addObserver(self, selector: #selector(getSSID), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        SVProgressHUD.setDefaultMaskType(.black)
        
        self.getSSID()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        SVProgressHUD.setDefaultMaskType(.none)
        airKiss?.closeConnection()  //断开socket
    }
    
    //获取SSID
    @objc func getSSID() {
        guard let ssidInfo = JMAirKissShareTools.fetchSSIDInfo() else { return }
        guard let ssid = (ssidInfo as! [String : Any])["SSID"]  else { return }
        
        ssidTF.text = ssid as? String
        ssidTF.isEnabled = false
    }
    
    //密碼明暗文切換
    @IBAction func pwdEyeAction(_ sender: Any) {
        pwdEyeBtn.isSelected = !pwdEyeBtn.isSelected
        if pwdEyeBtn.isSelected {
            let tempPwdStr = passwordTF.text
            passwordTF.text = ""  //这句代码可以防止切换的时候光标偏移
            passwordTF.isSecureTextEntry = false
            passwordTF.text = tempPwdStr
        }else{
            let tempPwdStr = passwordTF.text
            passwordTF.text = ""
            passwordTF.isSecureTextEntry = true
            passwordTF.text = tempPwdStr
        }
    }
    
    
    //配置网络事件
    @IBAction func connectAction(_ sender: Any) {
        if ssidTF.text?.lengthOfBytes(using: String.Encoding.utf8) == 0 {
            SVProgressHUD.showInfo(withStatus: "请输入WiFi名称")
            SVProgressHUD.dismiss(withDelay: 1.5)
            return
        }
        if passwordTF.text?.lengthOfBytes(using: String.Encoding.utf8) == 0 {
            SVProgressHUD.showInfo(withStatus: "请输入WiFi密码")
            SVProgressHUD.dismiss(withDelay: 1.5)
            return
        }
        //判断连接状态
        if !reachability!.isReachableViaWiFi(){
            SVProgressHUD.showInfo(withStatus: "请连接WiFi")
            SVProgressHUD.dismiss(withDelay: 1.5)
            return
        }
        ssidTF.resignFirstResponder()
        passwordTF.resignFirstResponder()
        
        SVProgressHUD.show(withStatus: "正在配网,请稍候...")
        //配网成功回调
        airKiss?.connectionSuccess = { 
            print("AirKiss配网成功")
            SVProgressHUD.showSuccess(withStatus: "配网成功")
            SVProgressHUD.dismiss(withDelay: 1.5)
        }
        
        //配网失败回调
        airKiss?.connectionFailure = {
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: "配网失败")
            SVProgressHUD.dismiss(withDelay: 1.5)
        }
        //开始配网
        airKiss?.connect(withSSID: ssidTF.text!, password: passwordTF.text!)
    }
    
    // MARK: UIView
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    //看下销毁没有
    deinit {
        print("看下销毁没有")
    }
    
    //懒加载
    fileprivate lazy var airKiss: FengAirKiss? = {
        let airK = FengAirKiss()
        airK.mac = self.mac!
        return airK
    }()
    
}
