# Sublime Text 2 开启 Vim 模式

首先按以下方式进入配置文件编辑界面: 

`Preferences -> Settings`

 (Mac下快捷键为 Command+,)

接下来会有两个文件： 

`Preferences.sublime-settings--Default` (默认设置，默认不可修改) 

`Preferences.sublime-settings--User` (用户设置，可以修改，且配置覆盖默认)

开启vim模式：在`Preferences.sublime-settings--User`用户设置中的`ignored_packages`对应的列表中去掉`Vintage`这一项:

```
// Settings in here override those in "Default/
Preferences.sublime-settings",
// and are overridden in turn by syntax-specific settings.
{
    "ignored_packages": []
}
```

关闭vim模式：把`Vintage`重新加上。

参考：https://blog.csdn.net/wukai_std/article/details/77998242