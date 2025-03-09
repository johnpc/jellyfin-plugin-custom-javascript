# Jellyfin Custom JavaScript Plugin

This plugin allows you to inject custom JavaScript code into the Jellyfin web UI. It provides a configuration page with a text area where you can enter any JavaScript code, which will then be executed when the Jellyfin web interface loads.

## Installation

### Automatic Installation (Recommended)

1. In Jellyfin, navigate to the Dashboard
2. Go to Plugins and then to the Catalog tab
3. Search for "Custom JavaScript"
4. Click on the plugin and then click the Install button

### Manual Installation

1. Download the latest release zip file from the [releases page](https://github.com/yourusername/jellyfin-customjavascript-plugin/releases)
2. Extract the contents to your Jellyfin plugins directory
   - On Linux: `/var/lib/jellyfin/plugins`
   - On Windows: `C:\ProgramData\Jellyfin\Server\plugins`
   - On Docker: `/jellyfin/plugins` (inside the container)
3. Restart Jellyfin

## Configuration

1. After installing the plugin, go to Dashboard → Plugins
2. Find "Custom JavaScript" in the list and click on it
3. In the text area, enter the JavaScript code you want to inject
4. Click Save
5. Refresh your browser to apply the changes

## Usage Examples

Here are some examples of what you can do with custom JavaScript:

### Change the Background Color

```javascript
document.body.style.backgroundColor = '#2d2d2d';
```

### Add a Custom Button to the Navigation Menu

```javascript
document.addEventListener('DOMContentLoaded', function() {
    // Wait for the sidebar menu to be available
    const checkInterval = setInterval(function() {
        const navDrawerItems = document.querySelector('.mainDrawer .navMenuOptionContainer');
        if (navDrawerItems) {
            clearInterval(checkInterval);
            
            // Create a new menu item
            const newMenuItem = document.createElement('a');
            newMenuItem.classList.add('navMenuOption', 'lnkMediaFolder');
            newMenuItem.href = 'https://example.com';
            newMenuItem.target = '_blank';
            newMenuItem.innerHTML = '<span class="material-icons navMenuOptionIcon">star</span><span class="navMenuOptionText">My Custom Link</span>';
            
            // Add it to the menu
            navDrawerItems.appendChild(newMenuItem);
        }
    }, 1000);
});
```

### Modify the CSS

```javascript
const customCSS = document.createElement('style');
customCSS.textContent = `
    .detailPageContent {
        max-width: 100% !important;
    }
    
    .card {
        border-radius: 10px !important;
        box-shadow: 0 4px 8px rgba(0,0,0,0.2) !important;
    }
`;
document.head.appendChild(customCSS);
```

## Development

### Building from Source

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/jellyfin-customjavascript-plugin.git
   ```

2. Build the plugin:
   ```
   dotnet build
   ```

3. The compiled dll will be in the `bin/Debug/net6.0` directory

### Project Structure

- `Plugin.cs` - The main plugin class
- `Configuration/PluginConfiguration.cs` - Defines the configuration model
- `Configuration/configPage.html` - The HTML for the configuration page
- `Web/customjavascript.js` - The JavaScript file that injects custom code into Jellyfin

## License

This plugin is licensed under the MIT License.

## Security Note

Be careful when using custom JavaScript as it can potentially introduce security vulnerabilities. Only use code from trusted sources or that you fully understand. The plugin author is not responsible for any issues caused by custom code entered by users.